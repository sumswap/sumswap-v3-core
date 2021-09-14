// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.6;
interface ITradeMint{
    
    function getFee(address tradeAddress,bytes calldata data,uint24 fee) external view returns (uint24);
    
    function getRelation(address tradeAddress,bytes calldata data) external view returns (address);
    
    function cross(int24 tick,int24 nextTick) external;
    
    function snapshot(bytes calldata data,int24 tick,uint256 liquidityVolumeGrowth,uint256 tradeVolume) external;
    
    function snapshotLiquidity(address poolAddress,uint128 liquidity,uint256 tokenId,int24 _tickLower,int24 _tickUpper) external;

    function snapshotMintLiquidity(address poolAddress,uint256 tokenId,int24 _tickLower,int24 _tickUpper) external;
    
    function getSuperFee() external view returns (uint24);

    function routerAddress() external view returns (address);
}