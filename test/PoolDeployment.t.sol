// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "src/mock/MockToken.sol";

// Import necessary contract for deployment
import "src/ExtendedPoolManager.sol";
import {CurrencyLibrary, Currency} from "v4-core/types/Currency.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import "v4-core/interfaces/IPoolManager.sol";
import "v4-core/types/PoolKey.sol";
import "v4-core/libraries/TickMath.sol";
import "v4-core/types/PoolId.sol";
import "src/AdaptativePoolHook.sol";



contract Implementation is AdaptativePoolHook {

    constructor(IPoolManager _poolManager, AdaptativePoolHook addressToEtch) AdaptativePoolHook(poolManager,50,3600,100,100_00,1_000,100,25){
        Hooks.isValidHookAddress(addressToEtch, 24);
    }

}



contract PoolDeployment is Test {

    AdaptativePoolHook hook = AdaptativePoolHook(address(uint160(Hooks.AFTER_SWAP_FLAG)));
    PoolManager manager;
    PoolKey poolKey;

    IERC20 token0;
    IERC20 token1;


    function setUp() public {
        token0 = new MockToken("weth", "WETH");
        token1 = new MockToken("usdc", "USDC");

        manager = new PoolManager(500000);

        Implementation impl = new Implementation(manager, hook);
        (, bytes32[] memory writes) = vm.accesses(address(impl));
        vm.etch(address(hook), address(impl).code);

        unchecked {
            for (uint256 i = 0; i < writes.length; i++) {
                bytes32 slot = writes[i];
                vm.store(address(hook), slot, vm.load(address(impl), slot));
            }
        }


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


    function test_swap() public {
        string memory poronga = manager.swap();
        assertEq(poronga, "poronga");

    }

}





// contract PoolDeployment is Test {
//     using PoolIdLibrary for PoolKey;
//     ERC20 token0;
//     ERC20 token1;

//     IExtendedPoolManager poolmanager;
    
//     AdaptativePoolHook adaptativePoolHook = AdaptativePoolHook(address(uint160(Hooks.AFTER_SWAP_FLAG)));
//     PoolKey poolKey;
//     PoolId poolId;

//     address user1;
//     address user2;

//     function setUp() public {
//         user1 = makeAddr("user1");
//         user2 = makeAddr("user2");
    

//         // Create tokens
//         token0 = new MockToken("weth", "WETH");
//         token1 = new MockToken("usdc", "USDC");

        // // Create PoolManager
        // poolmanager = new ExtendedPoolManager(500000);

        // // First create hook
        // _setupHook();

        

        // // Initialize PoolManager
        // // Make sure tokens are in order
        // if (token0 > token1){
        //     (token0, token1) = (token1, token0);
        // }
        // // Create Pool Key data
        // poolKey = PoolKey(
        //     // The lower currency of the pool, sorted numerically
        //     Currency.wrap(address(token0)), 
        //     // The higher currency of the pool, sorted numerically
        //     Currency.wrap(address(token1)),
        //     // The pool swap fee, capped at 1_000_000. The upper 4 bits determine if the hook sets any fees.
        //     uint24(100), // fee
        //     // Ticks that involve positions must be a multiple of tick spacing
        //     int24(60),
        //     // The hooks of the pool
        //     IHooks(address(adaptativePoolHook))
        // );

        // poolId = poolKey.toId();

        // // Test intermediate value 
        // uint160 sqrtPriceX96 = (TickMath.MAX_SQRT_RATIO + TickMath.MIN_SQRT_RATIO) / 2;
        
        // poolmanager.initialize(poolKey, sqrtPriceX96, "");
        
//    }


    // function test_FUCK() public {
    //     vm.startPrank(user1);

    //     poolmanager = new ExtendedPoolManager(500000);

    //     // adaptativePoolHook = new AdaptativePoolHook(poolmanager,50,3600,100,100_00,1_000,100,25);
    //     adaptativePoolHook = new AdaptativePoolHook(poolmanager,50,3600,100,100_00,1_000,100,25);


    //     if (token0 > token1){
    //         (token0, token1) = (token1, token0);
    //     }
    //     poolKey = PoolKey(
    //         Currency.wrap(address(token0)), 
    //         Currency.wrap(address(token1)),
    //         uint24(100), // fee
    //         int24(60),
    //         IHooks(address(adaptativePoolHook))
    //     );

    //     poolId = poolKey.toId();
    //     uint160 sqrtPriceX96 = (TickMath.MAX_SQRT_RATIO + TickMath.MIN_SQRT_RATIO) / 2;
    //     poolmanager.initialize(poolKey, sqrtPriceX96, "");


    // }


    // function _setupHook() internal{
    //     // HOOK creation
    //    adaptativePoolHook = new AdaptativePoolHook (
    //         // Pool Manager Contract
    //         poolmanager,
    //         // epochsToTrack
    //         50,
    //         // epochDuration (1h in seconds)
    //         3600,
    //         // minFee
    //         100,
    //         // maxFee
    //         100_00,
    //         // normalFee
    //         1_000,
    //         //epochDeltaFee
    //         100,
    //         // avgLiquidityVolumeThreshold
    //         25
    //    );
    // }



    // function test_token() public view {
    //     assertEq(token0.totalSupply(), 1000000 * 10**18);
    // }


    // function test_PoolManagerDeployed() public {
    //     poolmanager.MAX_TICK_SPACING();
    // }


    // function test_InitializePool() public {

    //     if (token0 > token1) {
    //         (token0, token1) = (token1, token0);
    //     }

    //     // Pool identification data
    //     PoolKey memory key = PoolKey(
    //         // The lower currency of the pool, sorted numerically
    //         Currency.wrap(address(token0)), 
    //         // The higher currency of the pool, sorted numerically
    //         Currency.wrap(address(token1)),
    //         // The pool swap fee, capped at 1_000_000. The upper 4 bits determine if the hook sets any fees.
    //         uint24(100), // fee
    //         // Ticks that involve positions must be a multiple of tick spacing
    //         int24(60),
    //         // The hooks of the pool
    //         IHooks(address(0))
    //     );

    //     // srtPriceX96 must be a value between MIN_SQRT_RATION - MAX_SQRT_RATIO
    //     // https://github.com/Uniswap/v4-core/blob/main/src/libraries/TickMath.sol#L24-L26
    //     uint160 sqrtPriceX96 = (TickMath.MAX_SQRT_RATIO + TickMath.MIN_SQRT_RATIO) / 2; // trying an intermediate value first
        

    //     poolmanager.initialize(key, sqrtPriceX96, "");
    // }


    // function test_HookCall() public {
    //     if (token0 > token1) {
    //         (token0, token1) = (token1, token0);
    //     }
    //     // Pool identification data
    //     PoolKey memory key = PoolKey(
    //         // The lower currency of the pool, sorted numerically
    //         Currency.wrap(address(token0)), 
    //         // The higher currency of the pool, sorted numerically
    //         Currency.wrap(address(token1)),
    //         // The pool swap fee, capped at 1_000_000. The upper 4 bits determine if the hook sets any fees.
    //         uint24(100), // fee
    //         // Ticks that involve positions must be a multiple of tick spacing
    //         int24(60),
    //         // The hooks of the pool
    //         IHooks(address(0))
    //     );

    //     // srtPriceX96 must be a value between MIN_SQRT_RATION - MAX_SQRT_RATIO
    //     // https://github.com/Uniswap/v4-core/blob/main/src/libraries/TickMath.sol#L24-L26
    //     uint160 sqrtPriceX96 = (TickMath.MAX_SQRT_RATIO + TickMath.MIN_SQRT_RATIO) / 2; // trying an intermediate value first
        
    //     poolmanager.initialize(key, sqrtPriceX96, "");
    // }



//}


