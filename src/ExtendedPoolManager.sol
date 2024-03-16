// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./interfaces/IExtendedPoolManager.sol";
import "v4-core/PoolManager.sol";

contract ExtendedPoolManager is PoolManager,IExtendedPoolManager{

    constructor(uint256 controllerGasLimit) PoolManager(controllerGasLimit) {}

    function getPoolFeeGrowth(
        PoolId poolId,
        bool isTokenZero
    ) 
    external
    view
    override
    returns(uint256){
        if (isTokenZero){
            return pools[poolId].feeGrowthGlobal0X128;
        }
        return pools[poolId].feeGrowthGlobal1X128;
    }

}