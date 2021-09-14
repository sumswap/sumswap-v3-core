// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.6;
pragma abicoder v2;

import '../interface/IPoolInitializer.sol'; 
import '../interface/ISummaSwapV3Factory.sol'; 
import '../interface/pool/ISummaSwapV3Pool.sol'; 
import './PeripheryImmutableState.sol';

abstract contract PoolInitializer is IPoolInitializer, PeripheryImmutableState {
    /// @inheritdoc IPoolInitializer
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable override returns (address pool) {
        require(token0 < token1);
        pool = ISummaSwapV3Factory(factory).getPool(token0, token1, fee);

        if (pool == address(0)) {
            pool = ISummaSwapV3Factory(factory).createPool(token0, token1, fee);
            ISummaSwapV3Pool(pool).initialize(sqrtPriceX96);
        } else {
            (uint160 sqrtPriceX96Existing, , , , , , ) = ISummaSwapV3Pool(pool).slot0();
            if (sqrtPriceX96Existing == 0) {
                ISummaSwapV3Pool(pool).initialize(sqrtPriceX96);
            }
        }
    }
}