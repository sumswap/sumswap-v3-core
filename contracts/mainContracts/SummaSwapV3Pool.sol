// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.7.6;
pragma abicoder v2;

import "../interface/pool/ISummaSwapV3Pool.sol";
import "../abstract/NoDelegateCall.sol";

import "../libraries/LowGasSafeMath.sol";
import "../libraries/SafeCast.sol";
import "../libraries/Tick.sol";
import "../libraries/TickBitmap.sol";
import "../libraries/Position.sol";
import "../libraries/Oracle.sol";
import "../libraries/SqrtPriceMath.sol";
import "../libraries/TransferHelper.sol";
import "../libraries/SwapMath.sol";

import "../interface/ISummaSwapV3MintCallback.sol";
import "../interface/ISummaSwapV3SwapCallback.sol";
import "../interface/ISummaSwapV3Factory.sol";
import "../interface/ISummaSwapV3PoolDeployer.sol";
import "../interface/trademint/ITradeMint.sol";

contract SummaSwapV3Pool is ISummaSwapV3Pool, NoDelegateCall {
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;
    using Tick for mapping(int24 => Tick.Info);
    using TickBitmap for mapping(int16 => uint256);
    using Position for mapping(bytes32 => Position.Info);
    using Position for Position.Info;
    using Oracle for Oracle.Observation[65535];

    /// @inheritdoc ISummaSwapV3PoolImmutables
    address public immutable override factory;
    /// @inheritdoc ISummaSwapV3PoolImmutables
    address public immutable override token0;
    /// @inheritdoc ISummaSwapV3PoolImmutables
    address public immutable override token1;
    /// @inheritdoc ISummaSwapV3PoolImmutables
    uint24 public immutable override fee;

    uint24 private takeFee;

    /// @inheritdoc ISummaSwapV3PoolImmutables
    int24 public immutable override tickSpacing;

    /// @inheritdoc ISummaSwapV3PoolImmutables
    uint128 public immutable override maxLiquidityPerTick;

    struct Slot0 {
        // the current price
        uint160 sqrtPriceX96;
        // the current tick
        int24 tick;
        // the most-recently updated index of the observations array
        uint16 observationIndex;
        // the current maximum number of observations that are being stored
        uint16 observationCardinality;
        // the next maximum number of observations to store, triggered in observations.write
        uint16 observationCardinalityNext;
        // the current protocol fee as a percentage of the swap fee taken on withdrawal
        // represented as an integer denominator (1/x)%
        uint8 feeProtocol;
        // whether the pool is locked
        bool unlocked;
    }
    /// @inheritdoc ISummaSwapV3PoolState
    Slot0 public override slot0;

    /// @inheritdoc ISummaSwapV3PoolState
    uint256 public override feeGrowthGlobal0X128;
    /// @inheritdoc ISummaSwapV3PoolState
    uint256 public override feeGrowthGlobal1X128;

    // accumulated protocol fees in token0/token1 units
    struct ProtocolFees {
        uint128 token0;
        uint128 token1;
    }

    /// @inheritdoc ISummaSwapV3PoolState
    ProtocolFees public override protocolFees;

    /// @inheritdoc ISummaSwapV3PoolState
    uint128 public override liquidity;

    /// @inheritdoc ISummaSwapV3PoolState
    mapping(int24 => Tick.Info) public override ticks;
    /// @inheritdoc ISummaSwapV3PoolState
    mapping(int16 => uint256) public override tickBitmap;
    /// @inheritdoc ISummaSwapV3PoolState
    mapping(bytes32 => Position.Info) public override positions;
    /// @inheritdoc ISummaSwapV3PoolState
    Oracle.Observation[65535] public override observations;

    modifier lock() {
        require(slot0.unlocked, "LOK");
        slot0.unlocked = false;
        _;
        slot0.unlocked = true;
    }
    /// @dev Prevents calling a function from anyone except the address returned by ISummaSwapV3Factory#owner()
    modifier onlyFactoryOwner() {
        require(msg.sender == ISummaSwapV3Factory(factory).owner());
        _;
    }

    constructor() {
        int24 _tickSpacing;
        (factory, token0, token1, fee, _tickSpacing) = ISummaSwapV3PoolDeployer(
            msg.sender
        ).parameters();
        tickSpacing = _tickSpacing;
        maxLiquidityPerTick = Tick.tickSpacingToMaxLiquidityPerTick(
            _tickSpacing
        );
    }

    /// @dev Returns the block timestamp truncated to 32 bits, i.e. mod 2**32. This method is overridden in tests.
    function _blockTimestamp() internal view virtual returns (uint32) {
        return uint32(block.timestamp); // truncation is desired
    }

    /// @dev Get the pool's balance of token0
    /// @dev This function is gas optimized to avoid a redundant extcodesize check in addition to the returndatasize
    /// check
    function balance0() private view returns (uint256) {
        (bool success, bytes memory data) = token0.staticcall(
            abi.encodeWithSelector(
                IERC20Minimal.balanceOf.selector,
                address(this)
            )
        );
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }

    /// @dev Get the pool's balance of token1
    /// @dev This function is gas optimized to avoid a redundant extcodesize check in addition to the returndatasize
    /// check
    function balance1() private view returns (uint256) {
        (bool success, bytes memory data) = token1.staticcall(
            abi.encodeWithSelector(
                IERC20Minimal.balanceOf.selector,
                address(this)
            )
        );
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }

    /// @inheritdoc ISummaSwapV3PoolActions
    /// @dev not locked because it initializes unlocked
    function initialize(uint160 sqrtPriceX96) external override {
        require(slot0.sqrtPriceX96 == 0, "AI");

        int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);

        (uint16 cardinality, uint16 cardinalityNext) = observations.initialize(
            _blockTimestamp()
        );

        slot0 = Slot0({
            sqrtPriceX96: sqrtPriceX96,
            tick: tick,
            observationIndex: 0,
            observationCardinality: cardinality,
            observationCardinalityNext: cardinalityNext,
            feeProtocol: 0,
            unlocked: true
        });

        emit Initialize(sqrtPriceX96, tick);
    }

    struct ModifyPositionParams {
        // the address that owns the position
        address owner;
        // the lower and upper tick of the position
        int24 tickL;
        int24 tickU;
        // any change in liquidity
        int128 liquidityDelta;
    }

    /// @dev Effect some changes to a position
    /// @param params the position details and the change to the position's liquidity to effect
    /// @return position a storage pointer referencing the position with the given owner and tick range
    /// @return amount0 the amount of token0 owed to the pool, negative if the pool should pay the recipient
    /// @return amount1 the amount of token1 owed to the pool, negative if the pool should pay the recipient
    function _modifyPosition(ModifyPositionParams memory params)
        private
        noDelegateCall
        returns (
            Position.Info storage position,
            int256 amount0,
            int256 amount1
        )
    {
        TickMath.checkTicks(params.tickL, params.tickU);
        Slot0 memory _slot0 = slot0; // SLOAD for gas optimization
        position = _updatePosition(
            params.owner,
            params.tickL,
            params.tickU,
            params.liquidityDelta,
            _slot0.tick
        );
        if (params.liquidityDelta != 0) {
            if (_slot0.tick < params.tickL) {
                // current tick is below the passed range; liquidity can only become in range by crossing from left to
                // right, when we'll need _more_ token0 (it's becoming more valuable) so user must provide it
                amount0 = SqrtPriceMath.getAmount0Delta(
                    TickMath.getSqrtRatioAtTick(params.tickL),
                    TickMath.getSqrtRatioAtTick(params.tickU),
                    params.liquidityDelta
                );
            } else if (_slot0.tick < params.tickU) {
                // current tick is inside the passed range
                uint128 liquidityBefore = liquidity; // SLOAD for gas optimization
                // write an oracle entry
                (
                    slot0.observationIndex,
                    slot0.observationCardinality
                ) = observations.write(
                    _slot0.observationIndex,
                    _blockTimestamp(),
                    _slot0.tick,
                    liquidityBefore,
                    _slot0.observationCardinality,
                    _slot0.observationCardinalityNext
                );
                amount0 = SqrtPriceMath.getAmount0Delta(
                    _slot0.sqrtPriceX96,
                    TickMath.getSqrtRatioAtTick(params.tickU),
                    params.liquidityDelta
                );
                amount1 = SqrtPriceMath.getAmount1Delta(
                    TickMath.getSqrtRatioAtTick(params.tickL),
                    _slot0.sqrtPriceX96,
                    params.liquidityDelta
                );
                liquidity = LiquidityMath.addDelta(
                    liquidityBefore,
                    params.liquidityDelta
                );
            } else {
                // current tick is above the passed range; liquidity can only become in range by crossing from right to
                // left, when we'll need _more_ token1 (it's becoming more valuable) so user must provide it
                amount1 = SqrtPriceMath.getAmount1Delta(
                    TickMath.getSqrtRatioAtTick(params.tickL),
                    TickMath.getSqrtRatioAtTick(params.tickU),
                    params.liquidityDelta
                );
            }
        }
    }

    function _updatePosition(
        address owner,
        int24 tickL,
        int24 tickU,
        int128 lDelta,
        int24 tick
    ) private returns (Position.Info storage position) {
        position = positions.get(owner, tickL, tickU);
        uint256 _feeGrowthGlobal0X128 = feeGrowthGlobal0X128; // SLOAD for gas optimization
        uint256 _feeGrowthGlobal1X128 = feeGrowthGlobal1X128; // SLOAD for gas optimization
        // if we need to update the ticks, do it
        bool flippedLower;
        bool flippedUpper;
        if (lDelta != 0) {
            uint32 time = _blockTimestamp();
            (
                int56 tickCumulative,
                uint160 secondsPerLiquidityCumulativeX128
            ) = observations.observeSingle(
                    time,
                    0,
                    slot0.tick,
                    slot0.observationIndex,
                    liquidity,
                    slot0.observationCardinality
                );

            flippedLower = ticks.update(
                tickL,
                tick,
                lDelta,
                _feeGrowthGlobal0X128,
                _feeGrowthGlobal1X128,
                secondsPerLiquidityCumulativeX128,
                tickCumulative,
                time,
                false,
                maxLiquidityPerTick
            );
            flippedUpper = ticks.update(
                tickU,
                tick,
                lDelta,
                _feeGrowthGlobal0X128,
                _feeGrowthGlobal1X128,
                secondsPerLiquidityCumulativeX128,
                tickCumulative,
                time,
                true,
                maxLiquidityPerTick
            );

            if (flippedLower) {
                tickBitmap.flipTick(tickL, tickSpacing);
            }
            if (flippedUpper) {
                tickBitmap.flipTick(tickU, tickSpacing);
            }
        }

        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) = ticks
            .getFeeGrowthInside(
                tickL,
                tickU,
                tick,
                _feeGrowthGlobal0X128,
                _feeGrowthGlobal1X128
            );

        position.update(lDelta, feeGrowthInside0X128, feeGrowthInside1X128);

        // clear any tick data that is no longer needed
        if (lDelta < 0) {
            if (flippedLower) {
                ticks.clear(tickL);
            }
            if (flippedUpper) {
                ticks.clear(tickU);
            }
        }
    }

    function mint(
        address recipient,
        int24 tickL,
        int24 tickU,
        uint128 amount,
        bytes calldata data
    ) external override lock returns (uint256 amount0, uint256 amount1) {
        require(amount > 0);
        (, int256 amount0Int, int256 amount1Int) = _modifyPosition(
            ModifyPositionParams({
                owner: recipient,
                tickL: tickL,
                tickU: tickU,
                liquidityDelta: int256(amount).toInt128()
            })
        );

        amount0 = uint256(amount0Int);
        amount1 = uint256(amount1Int);

        uint256 balance0Before;
        uint256 balance1Before;
        if (amount0 > 0) balance0Before = balance0();
        if (amount1 > 0) balance1Before = balance1();
        ISummaSwapV3MintCallback(msg.sender).summaSwapV3MintCallback(
            amount0,
            amount1,
            data
        );
        if (amount0 > 0)
            require(balance0Before.add(amount0) <= balance0(), "M0");
        if (amount1 > 0)
            require(balance1Before.add(amount1) <= balance1(), "M1");
        emit Mint(
            msg.sender,
            recipient,
            tickL,
            tickU,
            amount,
            amount0,
            amount1
        );
    }

    function collect(
        address recipient,
        int24 tickL,
        int24 tickU,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external override lock returns (uint128 amount0, uint128 amount1) {
        // we don't need to checkTicks here, because invalid positions will never have non-zero tokensOwed{0,1}
        Position.Info storage position = positions.get(
            msg.sender,
            tickL,
            tickU
        );

        amount0 = amount0Requested > position.tokensOwed0
            ? position.tokensOwed0
            : amount0Requested;
        amount1 = amount1Requested > position.tokensOwed1
            ? position.tokensOwed1
            : amount1Requested;

        if (amount0 > 0) {
            position.tokensOwed0 -= amount0;
            TransferHelper.safeTransfer(token0, recipient, amount0);
        }
        if (amount1 > 0) {
            position.tokensOwed1 -= amount1;
            TransferHelper.safeTransfer(token1, recipient, amount1);
        }

        emit Collect(msg.sender, recipient, tickL, tickU, amount0, amount1);
    }

    function burn(
        int24 tickL,
        int24 tickU,
        uint128 amount
    ) external override lock returns (uint256 amount0, uint256 amount1) {
        (
            Position.Info storage position,
            int256 amount0Int,
            int256 amount1Int
        ) = _modifyPosition(
                ModifyPositionParams({
                    owner: msg.sender,
                    tickL: tickL,
                    tickU: tickU,
                    liquidityDelta: -int256(amount).toInt128()
                })
            );

        amount0 = uint256(-amount0Int);
        amount1 = uint256(-amount1Int);

        if (amount0 > 0 || amount1 > 0) {
            (position.tokensOwed0, position.tokensOwed1) = (
                position.tokensOwed0 + uint128(amount0),
                position.tokensOwed1 + uint128(amount1)
            );
        }

        emit Burn(msg.sender, tickL, tickU, amount, amount0, amount1);
    }

    struct SwapCache {
        uint8 f;
        uint128 ls;
        uint32 b;
        int56 t;
        uint160 sc;
        bool cl;
    }
    struct SwapState {
        int256 am;
        int256 ad;
        uint160 sp;
        int24 tick;
        uint256 f;
        uint128 p;
        uint128 l;
        uint128 fa;
    }

    struct StepComputations {
        uint160 sp;
        int24 tN;
        bool inited;
        uint160 spNext;
        uint256 amountIn;
        uint256 amountOut;
        uint256 feeAmount;
    }

    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    )
        external
        override
        noDelegateCall
        returns (int256 amount0, int256 amount1)
    {
        require(amountSpecified != 0, "AS");

        Slot0 memory slot0Start = slot0;

        require(slot0Start.unlocked, "LOK");
        require(
            zeroForOne
                ? sqrtPriceLimitX96 < slot0Start.sqrtPriceX96 &&
                    sqrtPriceLimitX96 > TickMath.MIN_SQRT_RATIO
                : sqrtPriceLimitX96 > slot0Start.sqrtPriceX96 &&
                    sqrtPriceLimitX96 < TickMath.MAX_SQRT_RATIO,
            "SPL"
        );

        slot0.unlocked = false;

        SwapCache memory cache = SwapCache({
            ls: liquidity,
            b: _blockTimestamp(),
            f: zeroForOne
                ? (slot0Start.feeProtocol % 16)
                : (slot0Start.feeProtocol >> 4),
            sc: 0,
            t: 0,
            cl: false
        });

        bool exactInput = amountSpecified > 0;

        takeFee = ITradeMint(ISummaSwapV3Factory(factory).tradeMintAddress())
            .getFee(recipient, data, fee);

        SwapState memory state = SwapState({
            am: amountSpecified,
            ad: 0,
            sp: slot0Start.sqrtPriceX96,
            tick: slot0Start.tick,
            f: zeroForOne ? feeGrowthGlobal0X128 : feeGrowthGlobal1X128,
            p: 0,
            l: cache.ls,
            fa: 0
        });

        while (state.am != 0 && state.sp != sqrtPriceLimitX96) {
            StepComputations memory step;

            step.sp = state.sp;
            (step.tN, step.inited) = tickBitmap
                .nextInitializedTickWithinOneWord(
                    state.tick,
                    tickSpacing,
                    zeroForOne
                );

            if (step.tN < TickMath.MIN_TICK) {
                step.tN = TickMath.MIN_TICK;
            } else if (step.tN > TickMath.MAX_TICK) {
                step.tN = TickMath.MAX_TICK;
            }

            step.spNext = TickMath.getSqrtRatioAtTick(step.tN);

            (state.sp, step.amountIn, step.amountOut, step.feeAmount) = SwapMath
                .computeSwapStep(
                    state.sp,
                    (
                        zeroForOne
                            ? step.spNext < sqrtPriceLimitX96
                            : step.spNext > sqrtPriceLimitX96
                    )
                        ? sqrtPriceLimitX96
                        : step.spNext,
                    state.l,
                    state.am,
                    takeFee
                );

            if (exactInput) {
                state.am -= (step.amountIn + step.feeAmount).toInt256();
                state.ad = state.ad.sub(step.amountOut.toInt256());
            } else {
                state.am += step.amountOut.toInt256();
                state.ad = state.ad.add(
                    (step.amountIn + step.feeAmount).toInt256()
                );
            }

            if (cache.f > 0) {
                uint256 delta = step.feeAmount / cache.f;
                step.feeAmount -= delta;
                state.p += uint128(delta);
            }
            if (
                ITradeMint(ISummaSwapV3Factory(factory).tradeMintAddress())
                    .getRelation(recipient, data) != address(0)
            ) {
                uint256 delta = step.feeAmount /
                    ITradeMint(ISummaSwapV3Factory(factory).tradeMintAddress())
                        .getSuperFee();
                step.feeAmount -= delta;
                state.fa += uint128(delta);
            }

            if (state.l > 0) {
                state.f += FullMath.mulDiv(
                    step.feeAmount,
                    FixedPoint128.Q128,
                    state.l
                );
                if (
                    msg.sender ==
                    ITradeMint(ISummaSwapV3Factory(factory).tradeMintAddress())
                        .routerAddress()
                ) {
                    if (zeroForOne) {
                        ITradeMint(
                            ISummaSwapV3Factory(factory).tradeMintAddress()
                        ).snapshot(
                                data,
                                TickMath.getTickAtSqrtRatio(state.sp),
                                FullMath.mulDiv(
                                    step.amountIn,
                                    FixedPoint128.Q128,
                                    state.l
                                ),
                                step.amountIn
                            );
                    } else {
                        ITradeMint(
                            ISummaSwapV3Factory(factory).tradeMintAddress()
                        ).snapshot(
                                data,
                                TickMath.getTickAtSqrtRatio(state.sp),
                                FullMath.mulDiv(
                                    step.amountOut,
                                    FixedPoint128.Q128,
                                    state.l
                                ),
                                step.amountOut
                            );
                    }
                }
            }

            if (state.sp == step.spNext) {
                if (step.inited) {
                    if (!cache.cl) {
                        (cache.t, cache.sc) = observations.observeSingle(
                            cache.b,
                            0,
                            slot0Start.tick,
                            slot0Start.observationIndex,
                            cache.ls,
                            slot0Start.observationCardinality
                        );
                        cache.cl = true;
                    }
                    int128 liquidityNet = ticks.cross(
                        step.tN,
                        (zeroForOne ? state.f : feeGrowthGlobal0X128),
                        (zeroForOne ? feeGrowthGlobal1X128 : state.f),
                        cache.sc,
                        cache.t,
                        cache.b
                    );
                    ITradeMint(ISummaSwapV3Factory(factory).tradeMintAddress())
                        .cross(step.tN, zeroForOne ? step.tN - 1 : step.tN);
                    if (zeroForOne) liquidityNet = -liquidityNet;
                    state.l = LiquidityMath.addDelta(state.l, liquidityNet);
                }
                state.tick = zeroForOne ? step.tN - 1 : step.tN;
            } else if (state.sp != step.sp) {
                state.tick = TickMath.getTickAtSqrtRatio(state.sp);
            }
        }

        if (state.tick != slot0Start.tick) {
            (uint16 index, uint16 cardinality) = observations.write(
                slot0Start.observationIndex,
                cache.b,
                slot0Start.tick,
                cache.ls,
                slot0Start.observationCardinality,
                slot0Start.observationCardinalityNext
            );
            (
                slot0.sqrtPriceX96,
                slot0.tick,
                slot0.observationIndex,
                slot0.observationCardinality
            ) = (state.sp, state.tick, index, cardinality);
        } else {
            // otherwise just update the price
            slot0.sqrtPriceX96 = state.sp;
        }

        // update liquidity if it changed
        if (cache.ls != state.l) liquidity = state.l;

        // update fee growth global and, if necessary, protocol fees
        // overflow is acceptable, protocol has to withdraw before it hits type(uint128).max fees

        if (zeroForOne) {
            feeGrowthGlobal0X128 = state.f;
            if (state.p > 0) protocolFees.token0 += state.p;
            if (state.fa > 0) sendToken0(recipient, state.fa, data);
        } else {
            feeGrowthGlobal1X128 = state.f;
            if (state.p > 0) protocolFees.token1 += state.p;
            if (state.fa > 0) sendToken1(recipient, state.fa, data);
        }
        (amount0, amount1) = zeroForOne == exactInput
            ? (amountSpecified - state.am, state.ad)
            : (state.ad, amountSpecified - state.am);

        // do the transfers and collect payment
        if (zeroForOne) {
            if (amount1 < 0)
                TransferHelper.safeTransfer(
                    token1,
                    recipient,
                    uint256(-amount1)
                );

            uint256 balance0Before = balance0();
            ISummaSwapV3SwapCallback(msg.sender).summaSwapV3SwapCallback(
                amount0,
                amount1,
                data
            );
            require(balance0Before.add(uint256(amount0)) <= balance0(), "IIA");
        } else {
            if (amount0 < 0)
                TransferHelper.safeTransfer(
                    token0,
                    recipient,
                    uint256(-amount0)
                );

            uint256 balance1Before = balance1();
            ISummaSwapV3SwapCallback(msg.sender).summaSwapV3SwapCallback(
                amount0,
                amount1,
                data
            );
            require(balance1Before.add(uint256(amount1)) <= balance1(), "IIA");
        }

        emit Swap(
            msg.sender,
            recipient,
            amount0,
            amount1,
            state.sp,
            state.l,
            state.tick
        );
        slot0.unlocked = true;
    }

    function sendToken0(
        address recipient,
        uint128 amount,
        bytes calldata data
    ) private {
        TransferHelper.safeTransfer(
            token0,
            ITradeMint(ISummaSwapV3Factory(factory).tradeMintAddress())
                .getRelation(recipient, data),
            amount
        );
    }

    function sendToken1(
        address recipient,
        uint128 amount,
        bytes calldata data
    ) private {
        TransferHelper.safeTransfer(
            token1,
            ITradeMint(ISummaSwapV3Factory(factory).tradeMintAddress())
                .getRelation(recipient, data),
            amount
        );
    }

    /// @inheritdoc ISummaSwapV3PoolOwnerActions
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1)
        external
        override
        lock
        onlyFactoryOwner
    {
        require(
            (feeProtocol0 == 0 || (feeProtocol0 >= 4 && feeProtocol0 <= 10)) &&
                (feeProtocol1 == 0 || (feeProtocol1 >= 4 && feeProtocol1 <= 10))
        );
        uint8 feeProtocolOld = slot0.feeProtocol;
        slot0.feeProtocol = feeProtocol0 + (feeProtocol1 << 4);
        emit SetFeeProtocol(
            feeProtocolOld % 16,
            feeProtocolOld >> 4,
            feeProtocol0,
            feeProtocol1
        );
    }

    /// @inheritdoc ISummaSwapV3PoolOwnerActions
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    )
        external
        override
        lock
        onlyFactoryOwner
        returns (uint128 amount0, uint128 amount1)
    {
        amount0 = amount0Requested > protocolFees.token0
            ? protocolFees.token0
            : amount0Requested;
        amount1 = amount1Requested > protocolFees.token1
            ? protocolFees.token1
            : amount1Requested;

        if (amount0 > 0) {
            if (amount0 == protocolFees.token0) amount0--; // ensure that the slot is not cleared, for gas savings
            protocolFees.token0 -= amount0;
            TransferHelper.safeTransfer(token0, recipient, amount0);
        }
        if (amount1 > 0) {
            if (amount1 == protocolFees.token1) amount1--; // ensure that the slot is not cleared, for gas savings
            protocolFees.token1 -= amount1;
            TransferHelper.safeTransfer(token1, recipient, amount1);
        }

        emit CollectProtocol(msg.sender, recipient, amount0, amount1);
    }
}
