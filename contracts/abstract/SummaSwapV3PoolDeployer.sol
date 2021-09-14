// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.6;
pragma abicoder v2;

import '../interface/ISummaSwapV3PoolDeployer.sol';

import '../mainContracts/SummaSwapV3Pool.sol';

contract SummaSwapV3PoolDeployer is ISummaSwapV3PoolDeployer {
    struct Parameters {
        address factory;
        address token0;
        address token1;
        uint24 fee;
        int24 tickSpacing;
    }

    Parameters public override parameters;

    
    function deploy(
        address factory,
        address token0,
        address token1,
        uint24 fee,
        int24 tickSpacing
    ) internal returns (address pool) {
        parameters = Parameters({factory: factory, token0: token0, token1: token1, fee: fee, tickSpacing: tickSpacing});
        pool = address(new SummaSwapV3Pool{salt: keccak256(abi.encode(token0, token1, fee))}());
        delete parameters;
    }
}