// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.6;

import '../interface/IPeripheryImmutableState.sol'; 

abstract contract PeripheryImmutableState is IPeripheryImmutableState {
    /// @inheritdoc IPeripheryImmutableState
    address public immutable override factory;
    /// @inheritdoc IPeripheryImmutableState
    address public immutable override WETH9;

    constructor(address _factory, address _WETH9) {
        factory = _factory;
        WETH9 = _WETH9;
    }
}