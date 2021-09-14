import { Wallet,utils,BigNumber } from 'ethers'
import { MockTimeSummaSwapV3Manager } from '../../typechain'
import { FeeAmount, TICK_SPACINGS } from './constants'
import { encodePriceSqrt } from './encodePriceSqrt'
import { getMaxTick, getMinTick } from './ticks'


export async function createTestPool(
  nft: MockTimeSummaSwapV3Manager,
  wallet: Wallet,
  tokenAddressA: string,
  tokenAddressB: string
) {
  if (tokenAddressA.toLowerCase() > tokenAddressB.toLowerCase())
    [tokenAddressA, tokenAddressB] = [tokenAddressB, tokenAddressA]
    
  await nft.createAndInitializePoolIfNecessary(tokenAddressA, tokenAddressB, FeeAmount.LOW, BigNumber.from("2505411999795360582221170761428213"))

  const liquidityParams = {
    token0: tokenAddressA,
    token1: tokenAddressB,
    fee: FeeAmount.LOW,
    tickLower: 191150,
    tickUpper: 193380,
    recipient: wallet.address,
    amount0Desired: 0,
    amount1Desired: 99999999998804,
    amount0Min: 0,
    amount1Min: 99999999998804,
    deadline: 1,
    isLimt: false
  }
  return nft.mint(liquidityParams)
}


export async function createPool(
  nft: MockTimeSummaSwapV3Manager,
  wallet: Wallet,
  tokenAddressA: string,
  tokenAddressB: string
) {
  if (tokenAddressA.toLowerCase() > tokenAddressB.toLowerCase())
    [tokenAddressA, tokenAddressB] = [tokenAddressB, tokenAddressA]

  console.log("tokenAddressA ",tokenAddressA);
  console.log("tokenAddressB ",tokenAddressB);
  
  await nft.createAndInitializePoolIfNecessary(tokenAddressA, tokenAddressB, FeeAmount.MEDIUM, encodePriceSqrt(1, 1))
  
  const liquidityParams = {
    token0: tokenAddressA,
    token1: tokenAddressB,
    fee: FeeAmount.MEDIUM,
    tickLower: getMinTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
    tickUpper: getMaxTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
    recipient: wallet.address,
    amount0Desired: 1000000,
    amount1Desired: 1000000,
    amount0Min: 0,
    amount1Min: 0,
    deadline: 1,
    isLimt: false
  }
  
  return nft.mint(liquidityParams)
}


export async function createPoolWithMultiplePositions(
  nft: MockTimeSummaSwapV3Manager,
  wallet: Wallet,
  tokenAddressA: string,
  tokenAddressB: string
) {
  if (tokenAddressA.toLowerCase() > tokenAddressB.toLowerCase())
    [tokenAddressA, tokenAddressB] = [tokenAddressB, tokenAddressA]

  await nft.createAndInitializePoolIfNecessary(tokenAddressA, tokenAddressB, FeeAmount.MEDIUM, encodePriceSqrt(1, 1))

  const liquidityParams = {
    token0: tokenAddressA,
    token1: tokenAddressB,
    fee: FeeAmount.MEDIUM,
    tickLower: getMinTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
    tickUpper: getMaxTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
    recipient: wallet.address,
    amount0Desired: 1000000,
    amount1Desired: 1000000,
    amount0Min: 0,
    amount1Min: 0,
    deadline: 1,
    isLimt: false
  }

  await nft.mint(liquidityParams)

  const liquidityParams2 = {
    token0: tokenAddressA,
    token1: tokenAddressB,
    fee: FeeAmount.MEDIUM,
    tickLower: -60,
    tickUpper: 60,
    recipient: wallet.address,
    amount0Desired: 100,
    amount1Desired: 100,
    amount0Min: 0,
    amount1Min: 0,
    deadline: 1,
    isLimt: false
  }

  await nft.mint(liquidityParams2)

  const liquidityParams3 = {
    token0: tokenAddressA,
    token1: tokenAddressB,
    fee: FeeAmount.MEDIUM,
    tickLower: -120,
    tickUpper: 120,
    recipient: wallet.address,
    amount0Desired: 100,
    amount1Desired: 100,
    amount0Min: 0,
    amount1Min: 0,
    deadline: 1,
    isLimt: false
  }

  return nft.mint(liquidityParams3)
}

export async function createPoolWithZeroTickInitialized(
  nft: MockTimeSummaSwapV3Manager,
  wallet: Wallet,
  tokenAddressA: string,
  tokenAddressB: string
) {
  if (tokenAddressA.toLowerCase() > tokenAddressB.toLowerCase())
    [tokenAddressA, tokenAddressB] = [tokenAddressB, tokenAddressA]

  await nft.createAndInitializePoolIfNecessary(tokenAddressA, tokenAddressB, FeeAmount.MEDIUM, encodePriceSqrt(1, 1))

  const liquidityParams = {
    token0: tokenAddressA,
    token1: tokenAddressB,
    fee: FeeAmount.MEDIUM,
    tickLower: getMinTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
    tickUpper: getMaxTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
    recipient: wallet.address,
    amount0Desired: 1000000,
    amount1Desired: 1000000,
    amount0Min: 0,
    amount1Min: 0,
    deadline: 1,
    isLimt: false
  }

  await nft.mint(liquidityParams)

  const liquidityParams2 = {
    token0: tokenAddressA,
    token1: tokenAddressB,
    fee: FeeAmount.MEDIUM,
    tickLower: 0,
    tickUpper: 60,
    recipient: wallet.address,
    amount0Desired: 100,
    amount1Desired: 100,
    amount0Min: 0,
    amount1Min: 0,
    deadline: 1,
    isLimt: false
  }

  await nft.mint(liquidityParams2)

  const liquidityParams3 = {
    token0: tokenAddressA,
    token1: tokenAddressB,
    fee: FeeAmount.MEDIUM,
    tickLower: -120,
    tickUpper: 0,
    recipient: wallet.address,
    amount0Desired: 100,
    amount1Desired: 100,
    amount0Min: 0,
    amount1Min: 0,
    deadline: 1,
    isLimt: false
  }

  return nft.mint(liquidityParams3)
}
