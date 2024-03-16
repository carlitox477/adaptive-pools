// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./BaseHook.sol";
import "v4-core/types/PoolId.sol";
import "v4-core/types/PoolKey.sol";
import "v4-core/types/BalanceDelta.sol";
import "v4-core/interfaces/IPoolManager.sol";
import "v4-core/libraries/Pool.sol";
import "v4-core/libraries/Hooks.sol";

import "openzeppelin-contracts/Ownable2Step.sol";


/// @title Adaptive Pool Hook Contract
/// @dev This contract extends BaseHook to implement adaptive fee logic based on liquidity and volume dynamics.
/// @notice It adjusts pool fees dynamically based on the trading volume and liquidity within specified epochs.
error UnsafeCasting();

contract AdaptativePoolHook is BaseHook, Ownable2Step, TimelockController {
    using PoolIdLibrary for PoolKey;

    /// @dev Emitted when the pool mode changes.
    /// @param mode The new mode of the pool.
    event ModeChange(uint256 indexed mode);

    /// @dev Emitted when the minimum fee is updated.
    /// @param newValue The new minimum fee value.
    /// @param prevValue The previous minimum fee value.
    event NewMinFee(uint256 indexed newValue, uint256 prevValue);

    /// @dev Emitted when the normal fee is updated.
    /// @param newValue The new normal fee value.
    /// @param prevValue The previous normal fee value.
    event NewNormalFee(uint256 indexed newValue, uint256 prevValue);

    /// @dev Emitted when the maximum fee is updated.
    /// @param newValue The new maximum fee value.
    /// @param prevValue The previous maximum fee value.
    event NewMaxFee(uint256 indexed newValue, uint256 prevValue);

    /// @dev Emitted when liquidity volume for an epoch is recorded.
    /// @param currentLiquidity The current liquidity volume.
    /// @param finalizedEpochs The number of epochs finalized.
    event RecordLiquidityVolume(uint256 indexed currentLiquidity, uint128 finalizedEpochs);

    /// @dev Error thrown when an invalid mode is specified.
    /// @param mode The invalid mode that was provided.
    error WrongModeType(uint256 mode);
        
    uint256 constant FIXED_POOL = 1;
    uint256 constant DYNAMIC_POOL = 2;
    uint256 modeType;

    uint24 constant ONE_HUNDREAD_PERCENT = 100;
    uint24 immutable AVG_LIQUIDITY_VOLUME_THRESHOLD_PERCENT;
    uint24 immutable EPOCHS_TO_TRACK;
    uint64 immutable EPOCH_DURATION;
    uint24 MIN_FEE;
    uint24 MAX_FEE;
    uint24 NORMAL_FEE;
    uint24 immutable EPOCH_DELTA_FEE;
    PoolId immutable POOL_ID;
    
    PoolKey poolKey;
    
    uint128 finalizedEpochs;
    uint256[] lastEpochsVolume;
    uint64 lastSwapTimestamp;
    uint64 lastEpochUpdate;
    uint256 finishedEpochs;
    uint256 currentEpochLiquidityVolume;
    uint256 sumLastEpochLiquidityVolume;

    uint256 _feeGrowthBeforeSwap0X128;
    uint256 _feeGrowthBeforeSwap1X128;

    /// @notice Initializes a new Adaptive Pool Hook contract.
    /// @param _poolManager The address of the pool manager contract.
    /// @param epochsToTrack The number of epochs to track for liquidity volume.
    /// @param epochDuration The duration of each epoch.
    /// @param minFee The minimum fee percentage.
    /// @param maxFee The maximum fee percentage.
    /// @param normalFee The normal fee percentage within the expected range.
    /// @param epochDeltaFee The fee adjustment step size per epoch.
    /// @param avgLiquidityVolumeThreshold The threshold percentage for liquidity volume changes that trigger fee adjustments.
    /// @param _poolKey The pool key identifying the pool.
    constructor(
        IPoolManager _poolManager,
        uint24 epochsToTrack,
        uint64 epochDuration,
        uint24 minFee,
        uint24 maxFee,
        uint24 normalFee,
        uint24 epochDeltaFee,
        uint24 avgLiquidityVolumeThreshold,
        PoolKey memory _poolKey
    ) BaseHook(_poolManager) Ownable2Step(msg.sender){
        require(epochDuration != 0, "Epoch duration must be non-zero");
        require(minFee < maxFee, "Min fee must be less than max fee");
        require(normalFee <= maxFee, "Normal fee must be less than or equal to max fee");
        require(minFee <= normalFee, "Min fee must be less than or equal to normal fee");
        require(minFee % epochDeltaFee == 0, "Min fee must be a multiple of epoch delta fee");
        require(maxFee % epochDeltaFee == 0, "Max fee must be a multiple of epoch delta fee");
        require(normalFee % epochDeltaFee == 0, "Normal fee must be a multiple of epoch delta fee");
        require(avgLiquidityVolumeThreshold > 0 && avgLiquidityVolumeThreshold < ONE_HUNDREAD_PERCENT, "AVG liquidity volume threshold must be between 0 and 100 percent");

        EPOCHS_TO_TRACK = epochsToTrack; 
        EPOCH_DURATION = epochDuration;
        MIN_FEE = minFee;
        MAX_FEE = maxFee;
        NORMAL_FEE = normalFee;
        EPOCH_DELTA_FEE = epochDeltaFee;
        AVG_LIQUIDITY_VOLUME_THRESHOLD_PERCENT = avgLiquidityVolumeThreshold;
        lastEpochsVolume = new uint256[](epochsToTrack);
        poolKey = _poolKey;
        POOL_ID = _poolKey.toId();
    }

    /// @dev Called before a swap is executed to potentially update fee levels based on past liquidity volumes.
    /// @param swapParams Parameters of the swap.
    /// @return status A status code indicating if the swap can proceed.
    function beforeSwap(
        address, 
        PoolKey calldata,
        IPoolManager.SwapParams calldata swapParams,
        bytes calldata
    )
        external
        override
        poolManagerOnly()
        returns (bytes4 status)
    {
        if (_isNewEpoch()) {
            _recordEpochLiquidityVolume();

            if (finalizedEpochs >= EPOCHS_TO_TRACK) {
                uint256 avgLiquidityVolume = _calculateAvgLiquidityVolume();
                (uint256 minThreshold, uint256 maxThreshold) = _calculateAvgLiquidityVolumeThresholds(avgLiquidityVolume);
                _updateFees(avgLiquidityVolume, minThreshold, maxThreshold);
            }
            sumLastEpochLiquidityVolume = currentEpochLiquidityVolume;
            lastEpochUpdate = uint64(block.timestamp);
            currentEpochLiquidityVolume = 0;
        }

        lastSwapTimestamp = uint64(block.timestamp);
        _recordFeesBeforeSwap();
        return 0x150b7a02; // bytes4(keccak256("beforeSwap(address,PoolKey,IPoolManager.SwapParams,bytes)"))
    }

    /// @dev Determines if a new epoch has begun based on the last swap timestamp and epoch duration.
    /// @return isNewEpoch True if a new epoch has begun, false otherwise.
    function _isNewEpoch() internal view returns (bool isNewEpoch) {
        return lastEpochUpdate + EPOCH_DURATION < block.timestamp;
    }

    /// @dev Records the liquidity volume for the current epoch, updates the tracking array, and emits an event.
    function _recordEpochLiquidityVolume() internal {
        uint256 epochIndex = finalizedEpochs % EPOCHS_TO_TRACK;
        lastEpochsVolume[epochIndex] = currentEpochLiquidityVolume;
        ++finalizedEpochs;
        emit RecordLiquidityVolume(currentEpochLiquidityVolume, finalizedEpochs);
    }

    /// @dev Calculates the average liquidity volume over the tracked epochs.
    /// @return avgLiquidityVolume The average liquidity volume.
    function _calculateAvgLiquidityVolume() internal view returns (uint256 avgLiquidityVolume) {
        return sumLastEpochLiquidityVolume / EPOCHS_TO_TRACK;
    }

    /// @dev Calculates the thresholds for liquidity volume that trigger fee adjustments.
    /// @param avgLiquidityVolume The average liquidity volume.
    /// @return minThreshold The minimum threshold.
    /// @return maxThreshold The maximum threshold.
    function _calculateAvgLiquidityVolumeThresholds(uint256 avgLiquidityVolume) internal view returns (uint256 minThreshold, uint256 maxThreshold) {
        uint256 threshold = (avgLiquidityVolume * AVG_LIQUIDITY_VOLUME_THRESHOLD_PERCENT) / ONE_HUNDREAD_PERCENT;
        minThreshold = avgLiquidityVolume - threshold;
        maxThreshold = avgLiquidityVolume + threshold;
    }
    /// @dev Retrieves the current fee percentage of the pool.
    /// @return swapFee The current swap fee percentage of the pool.
    function _getPoolCurrentFeePercentage() internal view returns(uint24) {
        (,,, uint24 swapFee) = poolManager.getSlot0(POOL_ID);
        return swapFee;
    }

    /// @dev Retrieves the fee growth per liquidity unit for both tokens in the pool.
    /// @return feeGrowthPerLiquityUnit0 Fee growth per liquidity unit for token 0.
    /// @return feeGrowthPerLiquityUnit1 Fee growth per liquidity unit for token 1.
    function _getFeeGrowth() internal view returns(
        uint256 feeGrowthPerLiquityUnit0,
        uint256 feeGrowthPerLiquityUnit1
    ) {
        feeGrowthPerLiquityUnit0 = poolManager.getPoolFeeGrowth(POOL_ID, true);
        feeGrowthPerLiquityUnit1 = poolManager.getPoolFeeGrowth(POOL_ID, false);
    }

    /// @dev Records the fee growth before executing a swap.
    function _recordFeesBeforeSwap() internal {
        (_feeGrowthBeforeSwap0X128, _feeGrowthBeforeSwap1X128) = _getFeeGrowth();
    }

    /// @dev Updates the pool's swap fee based on the average liquidity volume and thresholds.
    /// @param avgLiquidityVolume Average liquidity volume calculated over a defined number of epochs.
    /// @param minThreshold Minimum liquidity volume threshold.
    /// @param maxThreshold Maximum liquidity volume threshold.
    function _updateFees(
        uint256 avgLiquidityVolume,
        uint256 minThreshold,
        uint256 maxThreshold
    ) internal {
        uint24 currentSwapFeePercentage = _getPoolCurrentFeePercentage();
        if(avgLiquidityVolume <= minThreshold) {
            if(currentSwapFeePercentage != MIN_FEE) {
                poolManager.updateDynamicSwapFee(poolKey, currentSwapFeePercentage - EPOCH_DELTA_FEE);
            }
        } else if(avgLiquidityVolume >= maxThreshold) {
            if(currentSwapFeePercentage != MAX_FEE) {
                poolManager.updateDynamicSwapFee(poolKey, currentSwapFeePercentage + EPOCH_DELTA_FEE);
            }
        } else if(currentSwapFeePercentage > NORMAL_FEE) {
            poolManager.updateDynamicSwapFee(poolKey, currentSwapFeePercentage - EPOCH_DELTA_FEE);
        } else if(currentSwapFeePercentage < NORMAL_FEE) {
            poolManager.updateDynamicSwapFee(poolKey, currentSwapFeePercentage + EPOCH_DELTA_FEE);
        }
    }

    /// @dev Returns the minimum of two values.
    /// @param x First value for comparison.
    /// @param y Second value for comparison.
    /// @return The smaller of the two input values.
    function _min(uint256 x, uint256 y) internal pure returns(uint256) {
        return x < y ? x : y;
    }

    /// @dev Returns the maximum of two values.
    /// @param x First value for comparison.
    /// @param y Second value for comparison.
    /// @return The larger of the two input values.
    function _max(uint256 x, uint256 y) internal pure returns(uint256) {
        return x > y ? x : y;
    }

    /// @notice Hook that is called after a swap has occurred.
    /// @dev Updates the current epoch's liquidity volume based on the swap's fee growth and amounts.
    /// @param amountsDelta The difference in amounts before and after the swap.
    /// @return status A status code indicating if the post-swap operations succeeded.
    function afterSwap(
        address,
        PoolKey calldata,
        IPoolManager.SwapParams calldata,
        BalanceDelta amountsDelta,
        bytes calldata
    )
        external
        override
        poolManagerOnly()
        returns (bytes4 status)
    {
        (uint256 _feeGrowthAfterSwap0X128, uint256 _feeGrowthAfterSwap1X128) = _getFeeGrowth();
        if(amountsDelta.amount0() > 0) {
            uint256 feeGrowthInSwap0 = _feeGrowthAfterSwap0X128 - _feeGrowthBeforeSwap0X128;
            currentEpochLiquidityVolume += _calculateLiquidityUtilized(
                uint256(uint128(amountsDelta.amount0())),
                18, // assuming 18 decimals here, adjust accordingly
                feeGrowthInSwap0
            );
        } else if(amountsDelta.amount1() > 0) {
            uint256 feeGrowthInSwap1 = _feeGrowthAfterSwap1X128 - _feeGrowthBeforeSwap1X128;
            currentEpochLiquidityVolume += _calculateLiquidityUtilized(
                uint256(uint128(amountsDelta.amount1())),
                18, // assuming 18 decimals here, adjust accordingly
                feeGrowthInSwap1
            );
        }
        return 0x150b7a02; // Custom status code or operation success code
    }

    /// @dev Calculates the amount of liquidity utilized during a swap.
    /// @param amountIn The amount of the input token.
    /// @param decimals The number of decimals of the input token.
    /// @param feeGrowthInSwap The fee growth captured during the swap.
    /// @return The calculated liquidity utilized for the swap.
    function _calculateLiquidityUtilized(
        uint256 amountIn,
        uint256 decimals,
        uint256 feeGrowthInSwap
    ) internal returns(uint256) {
        return amountIn * decimals / feeGrowthInSwap;
    }

    /// @notice Returns the permissions for the hook.
    /// @return hp The hook permissions.
    function getHookPermissions() public pure override returns (Hooks.Permissions memory hp) {
        // Implementation depends on specific permissions required by the hook.
    }

    /// @notice Changes the operation mode of the pool.
    /// @dev Allows for the dynamic adjustment between different pool operation modes.
    /// @param mode The desired operation mode for the pool.
    function changeMode(uint256 mode) external onlyAdmin {
        if (mode != DYNAMIC_POOL && mode != FIXED_POOL) {
            revert WrongModeType(mode);
        }
        modeType = mode;
        emit ModeChange(mode);
    }

    /// @notice Sets the maximum fee for the pool.
    /// @dev Can only be called by an admin, with changes subject to a timelock.
    /// @param _maxFee The desired maximum fee for the pool.
    function setMaxFee(uint256 _maxFee) external onlyAdmin {
        require(_maxFee > MIN_FEE &&
        _maxFee > NORMAL_FEE &&
        _maxFee % EPOCH_DELTA_FEE == 0, "Invalid max fee");

        uint256 previousMaxFee = MAX_FEE;
        MAX_FEE = _maxFee;
        emit NewMaxFee(_maxFee, previousMaxFee);
    }

    /// @notice Sets the minimum fee for the pool.
    /// @dev Can only be called by an admin, with changes subject to a timelock.
    /// @param _minFee The desired minimum fee for the pool.
    function setMinFee(uint256 _minFee) external onlyAdmin {
        require(_minFee < MAX_FEE &&
        _minFee < NORMAL_FEE &&
        _minFee % EPOCH_DELTA_FEE == 0, "Invalid min fee");

        uint256 previousMinFee = MIN_FEE;
        MIN_FEE = _minFee;
        emit NewMinFee(_minFee, previousMinFee);
    }

    /// @notice Sets the normal fee for the pool.
    /// @dev Can only be called by an admin, with changes subject to a timelock.
    /// @param _normalFee The desired normal fee for the pool.
    function setNormalFee(uint256 _normalFee) external onlyAdmin {
        require(_normalFee < MAX_FEE &&
        _normalFee > MIN_FEE &&
         _normalFee % EPOCH_DELTA_FEE == 0, "Invalid normal fee");
         
        uint256 previousNormalFee = NORMAL_FEE;
        NORMAL_FEE = _normalFee;
        emit NewNormalFee(_normalFee, previousNormalFee);
    }


}
