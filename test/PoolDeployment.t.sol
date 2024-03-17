// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "src/mock/MockToken.sol";

// Import necessary contract for deployment
import "v4-core/PoolManager.sol";
import {CurrencyLibrary, Currency} from "v4-core/types/Currency.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import "v4-core/interfaces/IPoolManager.sol";
import "v4-core/types/PoolKey.sol";
import "v4-core/libraries/TickMath.sol";
import "v4-core/types/PoolId.sol";
import "src/AdaptativePoolHook.sol";
import "v4-core/libraries/Pool.sol";


address constant HOOK_DEPLOYMENT_ADDRESS = address(uint160(
        Hooks.BEFORE_INITIALIZE_FLAG |
        Hooks.AFTER_INITIALIZE_FLAG |
        Hooks.BEFORE_SWAP_FLAG | 
        Hooks.AFTER_SWAP_FLAG 
        ));

uint24 constant DYNAMIC_FEE_FLAG = 24;

contract Implementation is AdaptativePoolHook {
    event SuccesfulImplementationCreation();

    constructor(
        IPoolManager _poolManager,
        AdaptativePoolHook addressToEtch
    ) AdaptativePoolHook(_poolManager,50,3600,100,100_00,1_000,100,25){
        Hooks.isValidHookAddress(addressToEtch, DYNAMIC_FEE_FLAG);
        emit SuccesfulImplementationCreation();
    }

}



contract PoolDeployment is Test {

    AdaptativePoolHook hook = AdaptativePoolHook(HOOK_DEPLOYMENT_ADDRESS);
    PoolManager manager;
    PoolKey poolKey;
    // Pool.SwapParams swapParameters;

    IERC20 token0;
    IERC20 token1;


    function setUp() public {
        token0 = new MockToken("weth", "WETH");
        token1 = new MockToken("usdc", "USDC");

        manager = new PoolManager(500000);

        Implementation impl = new Implementation(manager, hook);
        (, bytes32[] memory writes) = vm.accesses(address(impl));
        vm.etch(address(hook), address(impl).code);
        vm.label(HOOK_DEPLOYMENT_ADDRESS, "AdaptativePoolHook");

        unchecked {
            for (uint256 i = 0; i < writes.length; i++) {
                bytes32 slot = writes[i];
                vm.store(address(hook), slot, vm.load(address(impl), slot));
            }
        }

        // Order tokens
        if (token0 > token1){(token0, token1) = (token1, token0);}
        
        poolKey = PoolKey(
            Currency.wrap(address(token0)), 
            Currency.wrap(address(token1)),
            uint24(100),
            int24(60),
            IHooks(hook)
        );

        //PoolId poolId = PoolId.wrap(keccak256(abi.encode(poolKey)));
        uint160 sqrtPriceX96 = (TickMath.MAX_SQRT_RATIO + TickMath.MIN_SQRT_RATIO) / 2;        
        manager.initialize(poolKey, sqrtPriceX96, "");

    }


    function test_addLiquidity() public {
        // liquidity providers can provide liquidity at specific price ranges (ticks), 
        // allowing them to concentrate their liquidity and potentially earn more fees.
        
        token0.approve(address(manager), type(uint256).max);
        token1.approve(address(manager), type(uint256).max);


        IPoolManager.ModifyLiquidityParams memory liquidityParameters = IPoolManager.ModifyLiquidityParams({
            tickLower: int24(-600),
            tickUpper: int24(600),
            liquidityDelta: int256(1e18)
        });

        IPoolManager(address(manager)).modifyLiquidity(
            poolKey,
            liquidityParameters,
            ""
        );

        IPoolManager.SwapParams memory swapParams = IPoolManager.SwapParams({
            zeroForOne: bool(true),
            amountSpecified: int256(100),
            sqrtPriceLimitX96: 100
        });

        manager.swap(
            poolKey,
            swapParams, 
            ""
        );

    }


}






