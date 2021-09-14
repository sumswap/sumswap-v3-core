// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.7.6;

import '../interface/ISummaSwapV3Manager.sol';

contract SummaSwapV3ManagerPositionsGasTest {
    ISummaSwapV3Manager immutable summaSwapV3Manager;

    constructor(ISummaSwapV3Manager _summaSwapV3Manageranager) {
        summaSwapV3Manager = _summaSwapV3Manageranager;
    }

    function getGasCostOfPositions(uint256 tokenId) external view returns (uint256) {
        uint256 gasBefore = gasleft();
        summaSwapV3Manager.positions(tokenId);
        return gasBefore - gasleft();
    }
}
