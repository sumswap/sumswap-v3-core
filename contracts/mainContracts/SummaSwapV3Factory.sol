// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.7.6;
pragma abicoder v2;

import '../interface/ISummaSwapV3Factory.sol';
import '../abstract/NoDelegateCall.sol';
import '../abstract/SummaSwapV3PoolDeployer.sol';

contract SummaSwapV3Factory is ISummaSwapV3Factory, SummaSwapV3PoolDeployer, NoDelegateCall {

    // bytes32 public constant  override POOL_INIT_CODE_HASH =
    //     keccak256(abi.encodePacked(type(SummaSwapV3Pool).creationCode));

    address public override owner;

    address public override tradeMintAddress;

    mapping(uint24 => int24) public override feeAmountTickSpacing;
   
    mapping(address => mapping(address => mapping(uint24 => address))) public override getPool;

    constructor() {
        owner = msg.sender;
        emit OwnerChanged(address(0), msg.sender);

        feeAmountTickSpacing[500] = 10;
        emit FeeAmountEnabled(500, 10);
        feeAmountTickSpacing[3000] = 60;
        emit FeeAmountEnabled(3000, 60);
        feeAmountTickSpacing[10000] = 200;
        emit FeeAmountEnabled(10000, 200);
    }
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external override noDelegateCall returns (address pool) {
        require(tokenA != tokenB);
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0));
        int24 tickSpacing = feeAmountTickSpacing[fee];
        require(tickSpacing != 0);
        require(getPool[token0][token1][fee] == address(0));
        pool = deploy(address(this), token0, token1, fee, tickSpacing);
        getPool[token0][token1][fee] = pool;
        getPool[token1][token0][fee] = pool;
        emit PoolCreated(token0, token1, fee, tickSpacing, pool);
    }
    function setTradeMintAddress(address _tradeMintAddress) external override {
        require(msg.sender == owner);
        tradeMintAddress = _tradeMintAddress;
    }
    
    function setOwner(address _owner) external override {
        require(msg.sender == owner);
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }
    function enableFeeAmount(uint24 fee, int24 tickSpacing) public override {
        require(msg.sender == owner);
        require(fee < 1000000);
    
        require(tickSpacing > 0 && tickSpacing < 16384);
        require(feeAmountTickSpacing[fee] == 0);

        feeAmountTickSpacing[fee] = tickSpacing;
        emit FeeAmountEnabled(fee, tickSpacing);
    }
}
