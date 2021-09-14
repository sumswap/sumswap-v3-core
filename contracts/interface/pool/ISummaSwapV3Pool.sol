// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.6;
import './ISummaSwapV3PoolImmutables.sol'; 
import './ISummaSwapV3PoolState.sol'; 
import './ISummaSwapV3PoolActions.sol'; 
import './ISummaSwapV3PoolOwnerActions.sol'; 
import './ISummaSwapV3PoolEvents.sol'; 

interface ISummaSwapV3Pool is
    ISummaSwapV3PoolImmutables,
    ISummaSwapV3PoolState,
    ISummaSwapV3PoolActions,
    ISummaSwapV3PoolOwnerActions,
    ISummaSwapV3PoolEvents
{

}