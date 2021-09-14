// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.6;

interface ISummaSwapV3MintCallback {
    
    function summaSwapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;
}