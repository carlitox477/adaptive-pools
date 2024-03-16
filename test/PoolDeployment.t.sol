// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "src/mock/MockToken.sol";




contract PoolDeployment is Test {

    ERC20 token0;
    ERC20 token1;

    function setUp() public {
        token0 = new MockToken("weth", "WETH");
        token1 = new MockToken("usdc", "USDC");

    }

    function test_token() public view {
        assertEq(token0.totalSupply(), 1000000 * 10**18);
    }



}
