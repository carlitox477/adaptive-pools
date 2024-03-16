
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import {IPoolManager,PoolId} from "v4-core/interfaces/IPoolManager.sol";

interface IExtendedPoolManager is IPoolManager{
    function getPoolFeeGrowth(PoolId,bool) external view returns(uint256);
}
