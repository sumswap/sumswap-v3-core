// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.7.6;
pragma abicoder v2;

import '../mainContracts/SummaSwapV3Router.sol';

contract MockTimeSwapRouter is SummaSwapV3Router {
    uint256 time;

    constructor(address _factory, address _WETH9) SummaSwapV3Router(_factory, _WETH9) {}

    function _blockTimestamp() internal view override returns (uint256) {
        return time;
    }

    function setTime(uint256 _time) external {
        time = _time;
    }
}
