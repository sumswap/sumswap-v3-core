// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.6;
interface IPeripheryImmutableState {
    /// @return Returns the address of the SummaSwap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}