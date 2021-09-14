// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.6;
interface ISummaSwapV3PoolDeployer {
    
    function parameters()
        external
        view
        returns (
            address factory,
            address token0,
            address token1,
            uint24 fee,
            int24 tickSpacing
        );
}