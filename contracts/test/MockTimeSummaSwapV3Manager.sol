// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.7.6;
pragma abicoder v2;

import '../mainContracts/SummaSwapV3Manager.sol';

contract  MockTimeSummaSwapV3Manager is SummaSwapV3Manager {
    uint256 time;
    
    constructor(
        address _factory,
        address _WETH9,
        address _tokenDescriptor
    ) SummaSwapV3Manager(_factory, _WETH9, _tokenDescriptor) {}
    
    function _blockTimestamp() internal view override returns (uint256) {
        return time;
    }

    function setTime(uint256 _time) external {
        time = _time;
    }
}
