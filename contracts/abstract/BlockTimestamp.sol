// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.6;

 
abstract contract BlockTimestamp {
    /// @dev Method that exists purely to be overridden for tests
    /// @return The current block timestamp
    function _blockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}