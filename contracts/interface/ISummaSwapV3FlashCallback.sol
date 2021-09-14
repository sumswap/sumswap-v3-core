// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.6;
interface ISummaSwapV3FlashCallback {
   
    function summaSwapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external;
}