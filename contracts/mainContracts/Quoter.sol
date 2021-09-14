// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.7.6;
pragma abicoder v2;

import '../libraries/SafeCast.sol'; 
import '../libraries/Path.sol'; 
import '../libraries/Strings.sol';
import '../libraries/HexStrings.sol'; 
import '../libraries/PoolAddress.sol'; 
import '../libraries/CallbackValidation.sol'; 
import '../libraries/TickMath.sol';
import '../libraries/BitMath.sol';
import '../libraries/FullMath.sol';
import '../libraries/SqrtPriceMath.sol';
import '../libraries/LiquidityMath.sol';
import '../interface/ISummaSwapV3SwapCallback.sol'; 
import '../interface/pool/ISummaSwapV3Pool.sol'; 
import '../interface/IQuoter.sol'; 
import '../abstract/PeripheryImmutableState.sol'; 
import "hardhat/console.sol";


contract Quoter is IQuoter, ISummaSwapV3SwapCallback, PeripheryImmutableState {
    using Path for bytes;
    using SafeCast for uint256;
    using Strings for uint256;
    using HexStrings for uint256;
    
    /// @dev Transient storage variable used to check a safety condition in exact output swaps.
    uint256 private amountOutCached;

    constructor(address _factory, address _WETH9) PeripheryImmutableState(_factory, _WETH9) {}

    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) private view returns (ISummaSwapV3Pool) {
        return ISummaSwapV3Pool(PoolAddress.computeAddress(factory, PoolAddress.getPoolKey(tokenA, tokenB, fee)));
    }

    /// @inheritdoc ISummaSwapV3SwapCallback
    function summaSwapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes memory path
    ) external view override {
        require(amount0Delta > 0 || amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported
        (address tokenIn, address tokenOut, uint24 fee) = path.decodeFirstPool();
        CallbackValidation.verifyCallback(factory, tokenIn, tokenOut, fee);

        (bool isExactInput, uint256 amountToPay, uint256 amountReceived) =
            amount0Delta > 0
                ? (tokenIn < tokenOut, uint256(amount0Delta), uint256(-amount1Delta))
                : (tokenOut < tokenIn, uint256(amount1Delta), uint256(-amount0Delta));
        if (isExactInput) {
            assembly {
                let ptr := mload(0x40)
                mstore(ptr, amountReceived)
                revert(ptr, 32)
            }
        } else {
            // if the cache has been populated, ensure that the full output amount has been received
            if (amountOutCached != 0) require(amountReceived == amountOutCached);
            assembly {
                let ptr := mload(0x40)
                mstore(ptr, amountToPay)
                revert(ptr, 32)
            }
        }
    }

    /// @dev Parses a revert reason that should contain the numeric quote
    function parseRevertReason(bytes memory reason) private pure returns (uint256) {
        if (reason.length != 32) {
            if (reason.length < 68) revert('Unexpected error');
            assembly {
                reason := add(reason, 0x04)
            }
            revert(abi.decode(reason, (string)));
        }
        return abi.decode(reason, (uint256));
    }
    //            amountIn = quoteExactInputSingle(quoteAddress,tokenIn, tokenOut, fee, amountIn, 0);

    /// @inheritdoc IQuoter
    function quoteExactInputSingle(
        address quoteAddress,
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) public override returns (uint256 amountOut) {
        bool zeroForOne = tokenIn < tokenOut;
        console.log("hasMultiplePools 3 %s tokens", sqrtPriceLimitX96);
        try
            getPool(tokenIn, tokenOut, fee).swap(
                quoteAddress, 
                zeroForOne,
                amountIn.toInt256(),
                sqrtPriceLimitX96 == 0
                    ? (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
                    : sqrtPriceLimitX96,
                abi.encodePacked(tokenIn, fee, tokenOut)
            )
        {} catch (bytes memory reason) {
            return parseRevertReason(reason);
        }
    }
    /// @inheritdoc IQuoter
    function quoteExactInput(address quoteAddress,bytes memory path, uint256 amountIn) external override returns (uint256 amountOut) {
        while (true) {
            bool hasMultiplePools = path.hasMultiplePools();
            console.log("hasMultiplePools 1 %s tokens", hasMultiplePools);

            (address tokenIn, address tokenOut, uint24 fee) = path.decodeFirstPool();
            console.log("hasMultiplePools 2 %s tokens", hasMultiplePools);

            // the outputs of prior swaps become the inputs to subsequent ones
            amountIn = quoteExactInputSingle(quoteAddress,tokenIn, tokenOut, fee, amountIn, 0);
            console.log("hasMultiplePools 3 %s tokens", amountIn);

            // decide whether to continue or terminate
            if (hasMultiplePools) {
                path = path.skipToken();
            } else {
                return amountIn;
            }
        }
    }
    /// @inheritdoc IQuoter
    function quoteExactOutputSingle(
        address quoteAddress,
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) public override returns (uint256 amountIn) {
        bool zeroForOne = tokenIn < tokenOut;

        // if no price limit has been specified, cache the output amount for comparison in the swap callback
        if (sqrtPriceLimitX96 == 0) amountOutCached = amountOut;
        try
            getPool(tokenIn, tokenOut, fee).swap(
                quoteAddress, // address(0) might cause issues with some tokens
                zeroForOne,
                -amountOut.toInt256(),
                sqrtPriceLimitX96 == 0
                    ? (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
                    : sqrtPriceLimitX96,
                abi.encodePacked(tokenOut, fee, tokenIn)
            )
        {} catch (bytes memory reason) {
            if (sqrtPriceLimitX96 == 0) delete amountOutCached; // clear cache
            return parseRevertReason(reason);
        }
    }

    /// @inheritdoc IQuoter
    function quoteExactOutput(address quoteAddress,bytes memory path, uint256 amountOut) external override returns (uint256 amountIn) {
        while (true) {
            bool hasMultiplePools = path.hasMultiplePools();

            (address tokenOut, address tokenIn, uint24 fee) = path.decodeFirstPool();

            // the inputs of prior swaps become the outputs of subsequent ones
            amountOut = quoteExactOutputSingle(quoteAddress,tokenIn, tokenOut, fee, amountOut, 0);

            // decide whether to continue or terminate
            if (hasMultiplePools) {
                path = path.skipToken();
            } else {
                return amountOut;
            }
        }
    }
}
