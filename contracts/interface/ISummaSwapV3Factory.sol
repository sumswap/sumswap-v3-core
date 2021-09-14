// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.6;
pragma abicoder v2;
interface ISummaSwapV3Factory {
   
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    function setTradeMintAddress(address _tradeMintAddress) external;
    
    function tradeMintAddress() external view returns (address);
    
    function owner() external view returns (address);

    function feeAmountTickSpacing(uint24 fee) external view returns (int24);
    
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    function setOwner(address _owner) external;

    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}