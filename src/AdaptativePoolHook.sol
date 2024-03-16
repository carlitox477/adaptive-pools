// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
// lib/v4-periphery/contracts/BaseHook.sol
import "./BaseHook.sol";
import "v4-core/types/PoolId.sol";
import "v4-core/types/PoolKey.sol";
import "v4-core/types/BalanceDelta.sol";
import "v4-core/interfaces/IPoolManager.sol";
import "./interfaces/IExtendedPoolManager.sol";

import "v4-core/libraries/Pool.sol";
import "v4-core/libraries/Hooks.sol";
// import "v4-core/PoolManager.sol";

error UnsafeCasting();

contract AdaptativePoolHook is BaseHook {
    using PoolIdLibrary for PoolKey;

    uint24 constant ONE_HUNDREAD_PERCENT = 100;
    uint24 immutable AVG_LIQUIDITY_VOLUME_THESHOLD_PERCENT;
    uint24 immutable EPOCHS_TO_TRACK;
    uint64 immutable EPOCH_DURATION;
    uint24 immutable MIN_FEE;
    uint24 immutable MAX_FEE;
    uint24 immutable NORMAL_FEE;
    uint24 immutable EPOCH_DELTA_FEE;
    bool initialized;
    
    PoolId POOL_ID;
    PoolKey poolKey;
    
    uint128 finalizedEpochs;
    uint256[] lastEpochsVolume;
    uint64 lastSwapTimestamp;
    uint64 lastEpochUpdate;
    uint256 finishedEpochs;
    uint256 currentEpochLiquidityVolume;
    uint256 sumLastEpochLiquidityVolume; // type justification: ease implementation

    uint256 _feeGrowthBeforeSwap0X128;
    uint256 _feeGrowthBeforeSwap1X128;

    constructor(
        IPoolManager _poolManager,
        uint24 epochsToTrack,
        uint64 epochDuration,
        uint24 minFee,
        uint24 maxFee,
        uint24 normalFee,
        uint24 epochDeltaFee,
        uint24 avgLiquidityVolumeThreshold
    ) BaseHook(_poolManager) {
        require(epochDuration != 0);
        require(minFee < maxFee);
        require(normalFee < maxFee);
        require(minFee < normalFee);
        require(minFee % epochDeltaFee == 0);
        require(maxFee % epochDeltaFee == 0);
        require(normalFee % epochDeltaFee == 0);
        require(avgLiquidityVolumeThreshold > 0);
        require(avgLiquidityVolumeThreshold < ONE_HUNDREAD_PERCENT);
        

        EPOCHS_TO_TRACK = epochsToTrack; 
        EPOCH_DURATION = epochDuration;
        MIN_FEE = minFee;
        MAX_FEE = maxFee;
        NORMAL_FEE = normalFee;
        EPOCH_DELTA_FEE = epochDeltaFee;
        AVG_LIQUIDITY_VOLUME_THESHOLD_PERCENT = avgLiquidityVolumeThreshold;
        lastEpochsVolume = new uint256[](epochsToTrack);
    }

    function beforeInitialize(
        address,
        PoolKey calldata,
        uint160,
        bytes calldata
    ) 
        external
        poolManagerOnly()
        override
        returns (bytes4) 
    {
        require(!initialized);
    }

    // only once
    function afterInitialize(
        address,
        PoolKey calldata _poolKey,
        uint160,
        int24,
        bytes calldata
    )
        external
        poolManagerOnly()
        override
        returns (bytes4)
    {
        require(!initialized);
        poolKey = _poolKey;
        POOL_ID = _poolKey.toId();
        initialized = true;
    }

    function beforeSwap(
        address, 
        PoolKey calldata,
        IPoolManager.SwapParams calldata swapParams,
        bytes calldata
    )
        external
        override
        poolManagerOnly()
        returns (bytes4)
    {
        if(_isNewEpoch()){
            _recordEpochLiquidityVolume();
 

            // Calculate AVG volume in last
            // If finalizedEpochs < EPOCHS_TO_TRACK dynamics fees is disabled
            if(finalizedEpochs >= EPOCHS_TO_TRACK){
                uint256 avgLiquidityVolume = _calculateAvgLiquidityVolume();
                (uint256 minThreshold, uint256 maxThreshold) = _calculateAvgLiquidityVolumeThresholds(avgLiquidityVolume);
                _updateFees(avgLiquidityVolume,minThreshold,maxThreshold);
            }
            sumLastEpochLiquidityVolume = currentEpochLiquidityVolume;

            lastEpochUpdate = uint64(block.timestamp); //
            currentEpochLiquidityVolume = 0;
            
        }

        lastSwapTimestamp = uint64(block.timestamp);

        // Get fee growth to calculate used liquidity in after swap hook
        _recordFeesBeforeSwap();
    }

    function _isNewEpoch() internal view returns(bool){
        return lastEpochUpdate + EPOCH_DURATION < lastSwapTimestamp;
    }

    function _recordEpochLiquidityVolume() internal {
        uint256 epochIndex = finalizedEpochs % EPOCHS_TO_TRACK;
        int256 _lastEpochLiquidityVolume = int256(lastEpochsVolume[epochIndex]);
        int256 _currentEpochLiquidityVolume = int256(currentEpochLiquidityVolume);

        if(
            _lastEpochLiquidityVolume < 0 ||
            _currentEpochLiquidityVolume < 0 
        ){
            revert UnsafeCasting();
        }

        lastEpochsVolume[epochIndex] = currentEpochLiquidityVolume;
        unchecked{
            ++finalizedEpochs;
        }
    }

    function _calculateAvgLiquidityVolume() internal view returns (uint256){
        if(finalizedEpochs >= EPOCHS_TO_TRACK){
            return sumLastEpochLiquidityVolume / EPOCHS_TO_TRACK;
        }
    }

    function _calculateAvgLiquidityVolumeThresholds(
        uint256 avgLiquidityVolume
    ) internal view returns (uint256 minThreshold, uint256 maxThreshold){
        uint256 threshold = avgLiquidityVolume * AVG_LIQUIDITY_VOLUME_THESHOLD_PERCENT / ONE_HUNDREAD_PERCENT;
        minThreshold = avgLiquidityVolume - threshold;
        maxThreshold = avgLiquidityVolume + threshold;
    }

    function _getPoolCurrentFeePercentage() internal view returns(uint24){
        (,,, uint24 swapFee) = poolManager.getSlot0(POOL_ID);
        return swapFee;
    }

    function _getFeeGrowth() internal view returns(
        uint256 feeGrowthPerLiquityUnit0,
        uint256 feeGrowthPerLiquityUnit1
    ){
        feeGrowthPerLiquityUnit0 = IExtendedPoolManager(address(poolManager)).getPoolFeeGrowth(POOL_ID, true);
        feeGrowthPerLiquityUnit1 = IExtendedPoolManager(address(poolManager)).getPoolFeeGrowth(POOL_ID, false);

    }

    function _recordFeesBeforeSwap() internal {
        (_feeGrowthBeforeSwap0X128,_feeGrowthBeforeSwap0X128) = _getFeeGrowth();
    }

    function _updateFees(
        uint256 avgLiquidityVolume,
        uint256 minThreshold,
        uint256 maxThreshold
    ) internal{
        uint24 currentSwapFeePercentage = _getPoolCurrentFeePercentage();
        if(avgLiquidityVolume <= minThreshold){
            if(currentSwapFeePercentage != MIN_FEE){
                poolManager.updateDynamicSwapFee(poolKey,currentSwapFeePercentage - EPOCH_DELTA_FEE);
            }
        } else if(avgLiquidityVolume >= maxThreshold){

            if(currentSwapFeePercentage != MAX_FEE){
                poolManager.updateDynamicSwapFee(poolKey,currentSwapFeePercentage + EPOCH_DELTA_FEE);
            }
        }else if(currentSwapFeePercentage > NORMAL_FEE){
            poolManager.updateDynamicSwapFee(poolKey,currentSwapFeePercentage - EPOCH_DELTA_FEE);
        }else if(currentSwapFeePercentage < NORMAL_FEE){
            poolManager.updateDynamicSwapFee(poolKey,currentSwapFeePercentage + EPOCH_DELTA_FEE);
        }

    }

    function _min(uint256 x, uint256 y) internal pure returns(uint256){
        return x < y ? x : y;
    }

    function _max(uint256 x, uint256 y) internal pure  returns(uint256){
        return x > y ? x : y;
    }

    /*
    function _getPreviousEpochIndex(uint256 epochIndex)
        internal pure 
        returns(uint256)
    {
        return (epochIndex + EPOCHS_TO_TRACK - 1) % EPOCHS_TO_TRACK;
    }
    */

    error FUUUUUUUUCK();
    function afterSwap(
        address, 
        PoolKey calldata, 
        IPoolManager.SwapParams calldata,
        BalanceDelta amountsDelta, // the one positive represent tokens added swapped in
        bytes calldata
        )
        external
        override
        poolManagerOnly()
        returns (bytes4)
    {
    
        revert FUUUUUUUUCK();

        // // Update current liquidity volume
        // (uint256 _feeGrowthAfterSwap0X128,uint256 _feeGrowthAfterSwap1X128) = _getFeeGrowth();

        // // swapParams.amountSpecified > 0 --> user is specifying amountIn, easy to calculate
        // if(amountsDelta.amount0() > 0){
        //     uint256 feeGrowthInSwap0 = _feeGrowthAfterSwap0X128 - _feeGrowthBeforeSwap0X128;
        //     currentEpochLiquidityVolume += _calculateLiquidityUtilized(
        //         uint256(uint128(amountsDelta.amount0())),
        //         18, // modify decimals
        //         feeGrowthInSwap0
        //     );

        // }else if(amountsDelta.amount1() > 0){
        //     uint256 feeGrowthInSwap1 = _feeGrowthAfterSwap1X128 - _feeGrowthBeforeSwap1X128;
        //     currentEpochLiquidityVolume += _calculateLiquidityUtilized(
        //         uint256(uint128(amountsDelta.amount1())),
        //         18, // modify decimals
        //         feeGrowthInSwap1
        //     );
        // }
    }

    function _calculateLiquidityUtilized(
        uint256 amountIn,
        uint256 decimals,
        uint256 feeGrowthInSwap
    ) internal returns(uint256){
        // Fee decimals
        return amountIn * decimals/ feeGrowthInSwap;
    }


    function getHookPermissions() public pure override returns (Hooks.Permissions memory hp){
        return Hooks.Permissions(
            false, // beforeInitialize
            false, // afterInitialize true
            false, // beforeAddLiquidity
            false, // afterAddLiquidity
            false, // beforeRemoveLiquidity
            false, // afterRemoveLiquidity
            false, // beforeSwap true
            true, // afterSwap true
            false, // beforeDonate
            false // afterDonate
        );
    }


}

