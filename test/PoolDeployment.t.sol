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



contract PoolDeployment is Test {

    ERC20 token0;
    ERC20 token1;
    PoolManager pool;

    function setUp() public {
        token0 = new MockToken("weth", "WETH");
        token1 = new MockToken("usdc", "USDC");

        pool = new PoolManager(123);
    }

    function test_token() public view {
        assertEq(token0.totalSupply(), 1000000 * 10**18);
    }

    function test_PoolDeployed() public {
        pool.MAX_TICK_SPACING();
    }




}
