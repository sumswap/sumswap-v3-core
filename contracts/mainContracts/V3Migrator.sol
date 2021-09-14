// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.7.6;
pragma abicoder v2;

import '../interface/IV3Migrator.sol';
import '../abstract/PeripheryImmutableState.sol';
import '../abstract/PoolInitializer.sol';
import '../abstract/Multicall.sol';
import '../abstract/SelfPermit.sol';
import '../libraries/LowGasSafeMath.sol';
import '../libraries/TransferHelper.sol';
import '../interface/ISumiswapV2Pair.sol';

import '../interface/ISummaSwapV3Manager.sol';
import '../interface/IWETH9.sol';


contract V3Migrator is IV3Migrator, PeripheryImmutableState, PoolInitializer, Multicall, SelfPermit {
    using LowGasSafeMath for uint256;

    address public immutable summaSwapV3Manager;

    constructor(
        address _factory,
        address _WETH9,
        address _summaSwapV3Manager
    ) PeripheryImmutableState(_factory, _WETH9) {
        summaSwapV3Manager = _summaSwapV3Manager;
    }

    receive() external payable {
        require(msg.sender == WETH9, 'Not WETH9');
    }

    function migrate(MigrateParams calldata params) external override {
        require(params.percentageToMigrate > 0, 'Percentage too small');
        require(params.percentageToMigrate <= 100, 'Percentage too large');

        // burn v2 liquidity to this address
        ISumiswapV2Pair(params.pair).transferFrom(msg.sender, params.pair, params.liquidityToMigrate);
        (uint256 amount0V2, uint256 amount1V2) = ISumiswapV2Pair(params.pair).burn(address(this));

        // calculate the amounts to migrate to v3
        uint256 amount0V2ToMigrate = amount0V2.mul(params.percentageToMigrate) / 100;
        uint256 amount1V2ToMigrate = amount1V2.mul(params.percentageToMigrate) / 100;

        // approve the position manager up to the maximum token amounts
        TransferHelper.safeApprove(params.token0, summaSwapV3Manager, amount0V2ToMigrate);
        TransferHelper.safeApprove(params.token1, summaSwapV3Manager, amount1V2ToMigrate);

        // mint v3 position
        (, , uint256 amount0V3, uint256 amount1V3) =
            ISummaSwapV3Manager(summaSwapV3Manager).mint(
                ISummaSwapV3Manager.MintParams({
                    token0: params.token0,
                    token1: params.token1,
                    fee: params.fee,
                    tickLower: params.tickLower,
                    tickUpper: params.tickUpper,
                    amount0Desired: amount0V2ToMigrate,
                    amount1Desired: amount1V2ToMigrate,
                    amount0Min: params.amount0Min,
                    amount1Min: params.amount1Min,
                    recipient: params.recipient,
                    deadline: params.deadline,
                    isLimt:false
                })
            );

        // if necessary, clear allowance and refund dust
        if (amount0V3 < amount0V2) {
            if (amount0V3 < amount0V2ToMigrate) {
                TransferHelper.safeApprove(params.token0, summaSwapV3Manager, 0);
            }

            uint256 refund0 = amount0V2 - amount0V3;
            if (params.refundAsETH && params.token0 == WETH9) {
                IWETH9(WETH9).withdraw(refund0);
                TransferHelper.safeTransferETH(msg.sender, refund0);
            } else {
                TransferHelper.safeTransfer(params.token0, msg.sender, refund0);
            }
        }
        if (amount1V3 < amount1V2) {
            if (amount1V3 < amount1V2ToMigrate) {
                TransferHelper.safeApprove(params.token1, summaSwapV3Manager, 0);
            }

            uint256 refund1 = amount1V2 - amount1V3;
            if (params.refundAsETH && params.token1 == WETH9) {
                IWETH9(WETH9).withdraw(refund1);
                TransferHelper.safeTransferETH(msg.sender, refund1);
            } else {
                TransferHelper.safeTransfer(params.token1, msg.sender, refund1);
            }
        }
    }
}