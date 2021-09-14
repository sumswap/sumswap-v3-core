// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.7.6;
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xaf8dc78ed6578b2701c317308cd8f379451229b6bbeb4ce4c214d96aeb334f7b;

   
    function computeAddress(address factory, address token0,address token1,uint24 fee) internal pure returns (address pool) {
        require(token0 < token1);
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(token0, token1, fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        );
    }
}