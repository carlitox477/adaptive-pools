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
import "v4-core/types/PoolKey.sol";

// Periphery
// this breaks??? import "v4-periphery/BaseHook.sol";


contract PoolDeployment is Test {

    ERC20 token0;
    ERC20 token1;
    PoolManager poolmanager;

    function setUp() public {
        token0 = new MockToken("weth", "WETH");
        token1 = new MockToken("usdc", "USDC");

        poolmanager = new PoolManager(123);
    }


    function test_token() public view {
        assertEq(token0.totalSupply(), 1000000 * 10**18);
    }


    function test_PoolManagerDeployed() public {
        poolmanager.MAX_TICK_SPACING();
    }


    function test_InitializePool() public {

        if (token0 > token1) {
            (token0, token1) = (token1, token0);
        }

        // Pool identification data
        PoolKey memory key = PoolKey(
            // The lower currency of the pool, sorted numerically
            Currency.wrap(address(token0)), 
            // The higher currency of the pool, sorted numerically
            Currency.wrap(address(token1)),
            // The pool swap fee, capped at 1_000_000. The upper 4 bits determine if the hook sets any fees.
            uint24(100), // fee
            // Ticks that involve positions must be a multiple of tick spacing
            int24(60),
            // The hooks of the pool
            IHooks(address(0))
        );

        // srtPriceX96 must be a value between MIN_SQRT_RATION - MAX_SQRT_RATIO
        // https://github.com/Uniswap/v4-core/blob/main/src/libraries/TickMath.sol#L24-L26
        uint160 sqrtPriceX96 = (TickMath.MAX_SQRT_RATIO + TickMath.MIN_SQRT_RATIO) / 2; // trying an intermediate value first
        

        poolmanager.initialize(key, sqrtPriceX96, "");
    }


    function test_HookCall() public {
        
    }



}


contract TestHook {

    string name = "HONEYBOOBOO";

}