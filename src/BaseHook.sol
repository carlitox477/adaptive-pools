// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "v4-core/libraries/Hooks.sol";
import "v4-core/interfaces/IPoolManager.sol";
import "v4-core/interfaces/IHooks.sol";
import "v4-core/types/BalanceDelta.sol";
import "v4-core/types/PoolKey.sol";

/// @title Base Hook for Uniswap V4 Pools
/// @dev Provides an abstract base for custom hook implementations in Uniswap V4 pools, including validation and permission checks.
abstract contract BaseHook is IHooks {
    /// Errors that describe failures due to specific conditions.
    error NotPoolManager();
    error NotSelf();
    error InvalidPool();
    error LockFailure();
    error HookNotImplemented();

    /// @notice The address of the pool manager, immutable for the lifetime of the contract.
    IPoolManager public immutable poolManager;

    /// @dev Sets the pool manager upon contract creation and validates the hook's permissions.
    /// @param _poolManager Address of the pool manager contract.
    constructor(IPoolManager _poolManager) {
        poolManager = _poolManager;
        //validateHookAddress(this);
    }

    /// @notice Ensures a function is called by the pool manager only.
    modifier poolManagerOnly() {
        if (msg.sender != address(poolManager)) revert NotPoolManager();
        _;
    }

    /// @notice Ensures a function is called by the hook contract itself only.
    modifier selfOnly() {
        if (msg.sender != address(this)) revert NotSelf();
        _;
    }

    /// @notice Ensures a function is called for pools with hooks set to this contract only.
    /// @param hooks The IHooks interface of the calling contract.
    modifier onlyValidPools(IHooks hooks) {
        if (hooks != this) revert InvalidPool();
        _;
    }

    /// @notice Defines the hook permissions.
    /// @return A struct detailing the permissions of the hook.
    function getHookPermissions() public pure virtual returns (Hooks.Permissions memory);

    /// @dev Validates the hook address by checking its permissions.
    ///
    /// this function is virtual so that we can override it during testing,
    /// which allows us to deploy an implementation to any address
    /// and then etch the bytecode into the correct address
    /// @param _this The instance of the BaseHook being validated.
    function validateHookAddress(BaseHook _this) internal pure virtual {
        Hooks.validateHookPermissions(_this, getHookPermissions());
    }

    /// @notice Called when a lock is acquired, allowing the hook to perform actions.
    /// @param data The calldata to be executed.
    /// @return The return data from the executed call.
    function lockAcquired(bytes calldata data) external virtual poolManagerOnly returns (bytes memory) {
        (bool success, bytes memory returnData) = address(this).call(data);
        if (success) return returnData;
        if (returnData.length == 0) revert LockFailure();
        // if the call failed, bubble up the reason
        /// @solidity memory-safe-assembly
        assembly {
            revert(add(returnData, 32), mload(returnData))
        }
    }

    /// @notice Hook called before a pool is initialized.
    /// @dev Should be overridden in implementations; otherwise, it reverts.
    function beforeInitialize(address, PoolKey calldata, uint160, bytes calldata) external virtual returns (bytes4) {
        revert HookNotImplemented();
    }

    /// @notice Hook called after a pool is initialized.
    /// @dev Should be overridden in implementations; otherwise, it reverts.
    function afterInitialize(address, PoolKey calldata, uint160, int24, bytes calldata)
        external
        virtual
        returns (bytes4)
    {
        revert HookNotImplemented();
    }

    /// @notice Hook called before liquidity is added.
    /// @dev Should be overridden in implementations; otherwise, it reverts.
    function beforeAddLiquidity(address, PoolKey calldata, IPoolManager.ModifyLiquidityParams calldata, bytes calldata)
        external
        virtual
        returns (bytes4)
    {
        revert HookNotImplemented();
    }

    /// @notice Hook called before liquidity is removed.
    /// @dev Should be overridden in implementations; otherwise, it reverts.
    function beforeRemoveLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        revert HookNotImplemented();
    }

    /// @notice Hook called after liquidity is added.
    /// @dev Should be overridden in implementations; otherwise, it reverts.
    function afterAddLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        BalanceDelta,
        bytes calldata
    ) external virtual returns (bytes4) {
        revert HookNotImplemented();
    }

    /// @notice Hook called after liquidity is removed.
    /// @dev Should be overridden in implementations; otherwise, it reverts.
    function afterRemoveLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        BalanceDelta,
        bytes calldata
    ) external virtual returns (bytes4) {
        revert HookNotImplemented();
    }

    /// @notice Hook called before a swap occurs.
    /// @dev Should be overridden in implementations; otherwise, it reverts.
    function beforeSwap(address, PoolKey calldata, IPoolManager.SwapParams calldata, bytes calldata)
        external
        virtual
        returns (bytes4)
    {
        revert HookNotImplemented();
    }

    /// @notice Hook called after a swap occurs.
    /// @dev Should be overridden in implementations; otherwise, it reverts.
    function afterSwap(address, PoolKey calldata, IPoolManager.SwapParams calldata, BalanceDelta, bytes calldata)
        external
        virtual
        returns (bytes4)
    {
        revert HookNotImplemented();
    }

    /// @notice Hook called before a donation occurs.
    /// @dev Should be overridden in implementations; otherwise, it reverts.
    function beforeDonate(address, PoolKey calldata, uint256, uint256, bytes calldata)
        external
        virtual
        returns (bytes4)
    {
        revert HookNotImplemented();
    }

    /// @notice Hook called after a donation occurs.
    /// @dev Should be overridden in implementations; otherwise, it reverts.
    function afterDonate(address, PoolKey calldata, uint256, uint256, bytes calldata)
        external
        virtual
        returns (bytes4)
    {
        revert HookNotImplemented();
    }
}
