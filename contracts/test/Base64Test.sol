// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.7.6;

import '../libraries/Base64.sol';

contract Base64Test {
    function encode(bytes memory data) external pure returns (string memory) {
        return Base64.encode(data);
    }

    function getGasCostOfEncode(bytes memory data) external view returns (uint256) {
        uint256 gasBefore = gasleft();
        Base64.encode(data);
        return gasBefore - gasleft();
    }
}
