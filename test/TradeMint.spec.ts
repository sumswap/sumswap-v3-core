import { BigNumberish, constants, Wallet } from 'ethers'
import { waffle, ethers } from 'hardhat'

import { Fixture } from 'ethereum-waffle'
import {
  Summa,
  TokenIssue,
  SummaPri,
  TradeMint,
  TestPositionNFTOwner,
  MockTimeSummaSwapV3Manager,
  Quoter,
  TestERC20,
  IWETH9,
  ISummaSwapV3Factory,
  ISummaSwapV3Router,
} from '../typechain'
import completeFixture from './shared/completeFixture'
import { computePoolAddress } from './shared/computePoolAddress'
import { FeeAmount, MaxUint128, TICK_SPACINGS } from './shared/constants'
import { encodePriceSqrt } from './shared/encodePriceSqrt'
import { expect } from './shared/expect'
import getPermitNFTSignature from './shared/getPermitNFTSignature'
import { encodePath } from './shared/path'
import poolAtAddress from './shared/poolAtAddress'
import snapshotGasCost from './shared/snapshotGasCost'
import { getMaxTick, getMinTick } from './shared/ticks'
import { expandTo18Decimals } from './shared/expandTo18Decimals'
import { sortedTokens } from './shared/tokenSort'
import { extractJSONFromURI } from './shared/extractJSONFromURI'
import { abi as ISummaSwapV3PoolABI } from '../artifacts/contracts/interface/pool/ISummaSwapV3Pool.sol/ISummaSwapV3Pool.json'
import { createPool ,createTestPool} from './shared/quoter'
import { advanceBlockTo ,mineBlock,latest} from './shared/time'

describe('TradeMint', () => {
  let wallets: Wallet[]
  let wallet: Wallet, other: Wallet

  const nftFixture: Fixture<{
    summa: Summa
    tokenIssue: TokenIssue
    summaPri: SummaPri
    tradeMint: TradeMint
    nft: MockTimeSummaSwapV3Manager
    factory: ISummaSwapV3Factory
    quoter: Quoter
    tokens: [TestERC20, TestERC20, TestERC20]
    weth9: IWETH9
    router: ISummaSwapV3Router
  }> = async (wallets, provider) => {
    const { quoter,summa,tokenIssue,summaPri,tradeMint,weth9, factory, tokens, nft, router } = await completeFixture(wallets, provider)

    // approve & fund wallets
    for (const token of tokens) {
      await token.approve(nft.address, constants.MaxUint256)
      await token.connect(other).approve(nft.address, constants.MaxUint256)
      await token.transfer(other.address, expandTo18Decimals(1_000_000))
    }

    // for (const token of tokens) {
    //   await token.approve(nft.address, constants.MaxUint256)
    //   await token.connect(other).approve(nft.address, constants.MaxUint256)
    //   await token.transfer(other.address, expandTo18Decimals(1_000_000))
    //   let allowance = await token.allowance(wallet.address,nft.address);
    //   console.log("allowance ",ethers.utils.formatEther(allowance.toString()));
    // }
    return {
      summa,
      tokenIssue,
      summaPri,
      tradeMint,
      nft,
      factory,
      tokens,
      weth9,
      router,
      quoter
    }
  }

  let summa: Summa
  let tokenIssue: TokenIssue
  let summaPri: SummaPri
  let tradeMint: TradeMint
  let factory: ISummaSwapV3Factory
  let quoter: Quoter
  let nft: MockTimeSummaSwapV3Manager
  let tokens: [TestERC20, TestERC20, TestERC20]
  let weth9: IWETH9
  let router: ISummaSwapV3Router

  let loadFixture: ReturnType<typeof waffle.createFixtureLoader>

  before('create fixture loader', async () => {
    wallets = await (ethers as any).getSigners();
    [wallet, other] = wallets
    loadFixture = waffle.createFixtureLoader(wallets)
  })

  beforeEach('load fixture', async () => {
    ;({ summa, tokenIssue, summaPri,tradeMint,nft, factory, tokens, weth9, router ,quoter} = await loadFixture(nftFixture))
     // approve & fund wallets
     for (const token of tokens) {
      await token.approve(router.address, constants.MaxUint256)
      await token.approve(nft.address, constants.MaxUint256)
      await token.connect(other).approve(router.address, constants.MaxUint256)
      await token.transfer(other.address, expandTo18Decimals(1_000_000))
    }
  })
  
   //创建流动性池并添加流动性  这个位置可以修改
   beforeEach(async () => {
    const [token0, token1] = sortedTokens(tokens[0], tokens[1])

    // const poolAddress = computePoolAddress(factory.address, [tokens[0].address, tokens[1].address], FeeAmount.MEDIUM)
    // console.log("enableReward 1111111 factory" ,factory.address) ;
    // console.log("enableReward 1111111 token0" ,token0.address) ;
    // console.log("enableReward 1111111 token1" ,token1.address) ;
    // console.log("enableReward 1111111 FeeAmount" ,FeeAmount.MEDIUM) ;
    // console.log("enableReward 1111111 poolAddress " ,poolAddress) ;
    // await createPool(nft, wallet, tokens[0].address, tokens[1].address)
    // await tradeMint['enableReward(address,address,uint24,bool,uint256)'](token0.address ,token1.address,FeeAmount.MEDIUM ,true,100);
    // await tradeMint['enableReward(address,bool,uint256)']("0x5058e7669869decee586cbdf769542230f479d8b" , true,100);
    // expect(await tradeMint.totalRewardShare()).to.equal(100)

    //await createPool(nft, wallet, tokens[0].address, tokens[1].address)
    //await createPool(nft, wallet, tokens[1].address, tokens[2].address)
  })
  
//   //兑换计算测试
//   it('0 -> 1', async () => {
//     const quote = await quoter.callStatic.quoteExactInput(
//       wallet.address,
//       encodePath([tokens[0].address, tokens[1].address], [FeeAmount.MEDIUM]),
//       100
//     )
//     expect(quote).to.eq(98)
//  })
 
//  //移动到第100个区块
//  it('blockTo 100', async () => {
//   await  advanceBlockTo(100);
//   expect(await ethers.provider.getBlockNumber()).to.equal(100)
//   expect(await tokenIssue.currentBlock()).to.equal(100)
//  })

//  //计算当前发行的Token 
//  it('tokenIssue ', async () => {
//   await  advanceBlockTo(1000);
//   // expect(await ethers.provider.getBlockNumber()).to.equal(102)
//   // expect(await tokenIssue.currentBlock()).to.equal(102)
//   const currentCanIssueAmount =  await tokenIssue.currentCanIssueAmount();
//   console.log(ethers.utils.formatEther(currentCanIssueAmount.toString()).toString());

//   const currentBlockCanIssueAmount =  await tokenIssue.currentBlockCanIssueAmount();
//   console.log(ethers.utils.formatEther(currentBlockCanIssueAmount.toString()).toString());
// })

// //开启流动性奖励
// it('enableReward  ', async () => {
//   expect(await tradeMint.easterEggReward()).to.equal(0)
//   const [token0, token1] = sortedTokens(tokens[0], tokens[1])

//   const poolAddress = computePoolAddress(
//     factory.address,
//     [token0.address, token1.address],
//     FeeAmount.MEDIUM
//   )
//   console.log("enableReward 1111111 factory" ,factory.address) ;
//   console.log("enableReward 1111111 token0" ,token0.address) ;
//   console.log("enableReward 1111111 token1" ,token1.address) ;
//   console.log("enableReward 1111111 FeeAmount" ,FeeAmount.MEDIUM) ;
//   console.log("enableReward 1111111 poolAddress " ,poolAddress) ;
    
//   await tradeMint['enableReward(address,address,uint24,bool,uint256)'](token0.address.toLowerCase() ,token1.address.toLowerCase(),FeeAmount.MEDIUM ,true,100);
//   expect(await tradeMint.totalRewardShare()).to.equal(200)
// })


// //查看当前地址流动性奖励
// it('pendingSumma  ', async () => {
//   expect(await tradeMint.pendingSumma(other.address)).to.equal(0)
// })

// //添加池的流动性
// it('mint nft  ', async () => {
//   await nft.mint({
//     token0: tokens[0].address,
//     token1: tokens[1].address,
//     tickLower: getMinTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
//     tickUpper: getMaxTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
//     fee: FeeAmount.MEDIUM,
//     recipient: other.address,
//     amount0Desired: 20000,
//     amount1Desired: 20000,
//     amount0Min: 0,
//     amount1Min: 0,
//     deadline: 10,
//     isLimt: false
//   })
  
//   expect(await nft.balanceOf(other.address)).to.eq(1)
//   expect(await nft.tokenOfOwnerByIndex(other.address, 0)).to.eq(2)
//   const {
//     fee,
//     token0,
//     token1,
//     tickLower,
//     tickUpper,
//     liquidity,
//     tokensOwed0,
//     tokensOwed1,
//     feeGrowthInside0LastX128,
//     feeGrowthInside1LastX128,
//   } = await nft.positions(1)
//   expect(token0).to.eq(tokens[0].address)
//   expect(token1).to.eq(tokens[1].address)
//   expect(fee).to.eq(FeeAmount.MEDIUM)
//   expect(tickLower).to.eq(getMinTick(TICK_SPACINGS[FeeAmount.MEDIUM]))
//   expect(tickUpper).to.eq(getMaxTick(TICK_SPACINGS[FeeAmount.MEDIUM]))
//   expect(liquidity).to.eq(1000000)
//   expect(tokensOwed0).to.eq(0)
//   expect(tokensOwed1).to.eq(0)
//   expect(feeGrowthInside0LastX128).to.eq(0)
//   expect(feeGrowthInside1LastX128).to.eq(0)
// })

// //兑换代币
// describe('10k of token0 fees collect', () => {
//     beforeEach('swap for ~10k of fees', async () => {
//       const swapAmount = 3_333_333
//       await tokens[0].approve(router.address, swapAmount)
//       await router.exactInput({
//         recipient: wallet.address,
//         deadline: 1,
//         path: encodePath([tokens[0].address, tokens[1].address], [FeeAmount.MEDIUM]),
//         amountIn: swapAmount,
//         amountOutMinimum: 0,
//       })
//     })
//     it('expected amounts', async () => {
//       const { amount0: nft1Amount0, amount1: nft1Amount1 } = await nft.callStatic.collect({
//         tokenId: 1,
//         recipient: wallet.address,
//         amount0Max: MaxUint128,
//         amount1Max: MaxUint128,
//       })
//       expect(nft1Amount0).to.eq(10000)
//       expect(nft1Amount1).to.eq(0)
//     })

//     it('actually collected', async () => {
//       const poolAddress = computePoolAddress(
//         factory.address,
//         [tokens[0].address, tokens[1].address],
//         FeeAmount.MEDIUM
//       )
      
//       const info  = await nft.collect({
//         tokenId: 1,
//         recipient: wallet.address,
//         amount0Max: MaxUint128,
//         amount1Max: MaxUint128,
//       })
//     })
// })

// //查看当前地址流动性奖励信息
// it('pendingSumma  ', async () => {
//   expect(await tradeMint.totalRewardShare()).to.equal(100)

//   expect(await tradeMint.pendingSumma(other.address)).to.equal(0)
//   expect(await tradeMint.pendingSumma(wallet.address)).to.equal(0)

//   const [token0, token1] = sortedTokens(tokens[0], tokens[1])
//   const poolAddress = computePoolAddress(
//     factory.address,
//     [token0.address, token1.address,],
//     FeeAmount.MEDIUM
//   )
//   //console.log("poolAddress" ,poolAddress) ;

//   expect(await tradeMint.getPendingSummaByTokenId(1)).to.equal(0)
//   expect(await tradeMint.getPoolReward(poolAddress)).to.equal(0)
//   // expect(await tradeMint.getMultiplier(0,1000).to.equal(0))
// })


// 奖池信息
it('PoolReward', async () => {

  //A用户创建一个池
  await createPool(nft, wallet, tokens[0].address, tokens[1].address) 

  //添加奖励
  await tradeMint['enableReward(address,bool,uint256)']("0x5058e7669869decee586cbdf769542230f479d8b" , true,100);
  //查看当前奖励份额总量
  expect(await tradeMint.totalRewardShare()).to.equal(100)
  
  //B用户创建一个池
  await createPool(nft, other, tokens[0].address, tokens[2].address) 
  //添加奖励
  await tradeMint['enableReward(address,bool,uint256)']("0xcb3f0014a292dbf2cf1ca5c55b7e6141e1ec1aaa" , true,100);
  //查看当前奖励份额总量
  expect(await tradeMint.totalRewardShare()).to.equal(200)

  //移动区块前查看当前的奖励情况
  expect(await tradeMint.pendingSumma(other.address)).to.equal(0)
  expect(await tradeMint.pendingSumma(wallet.address)).to.equal(0)
  //奖池信息
  expect(await tradeMint.getPoolReward("0x5058e7669869decee586cbdf769542230f479d8b")).to.equal("44444444444444444439")
  expect(await tradeMint.getPoolReward("0xcb3f0014a292dbf2cf1ca5c55b7e6141e1ec1aaa")).to.equal("44444444444444444439")

  await  advanceBlockTo(1000);
  
  //移动区块后查看当前的奖励情况
  expect(await tradeMint.pendingSumma(other.address)).to.equal(0)
  expect(await tradeMint.pendingSumma(wallet.address)).to.equal(0)
  expect(await tradeMint.getPendingSummaByTokenId(1)).to.equal(0)
  //奖池信息
  expect(await tradeMint.getPoolReward("0x5058e7669869decee586cbdf769542230f479d8b")).to.equal("44444444444444444439")
  expect(await tradeMint.getPoolReward("0xcb3f0014a292dbf2cf1ca5c55b7e6141e1ec1aaa")).to.equal("44444444444444444439")
  expect(await ethers.provider.getBlockNumber()).to.equal(1000)

  await  advanceBlockTo(2000);
  expect(await ethers.provider.getBlockNumber()).to.equal(2000)

  //用户A兑换代币
  const swapAmount = 1000
  await tokens[0].connect(wallet).approve(router.address, swapAmount)
  await router.connect(wallet).exactInput({
    recipient: wallet.address,
    deadline: 1,
    path: encodePath([tokens[0].address, tokens[1].address], [FeeAmount.MEDIUM]),
    amountIn: swapAmount,
    amountOutMinimum: 0,
  })

  //提取手续费
  const { amount0: wallet_nft1Amount0, amount1: wallet_nft1Amount1 } = await nft.connect(wallet).callStatic.collect({
    tokenId: 1,
    recipient: wallet.address,
    amount0Max: MaxUint128,
    amount1Max: MaxUint128,
  })
  expect(wallet_nft1Amount0).to.eq(2)
  expect(wallet_nft1Amount1).to.eq(0)
  
  expect(await tradeMint.pendingSumma(wallet.address)).to.equal(0)
  expect(await tradeMint.pendingSumma(other.address)).to.equal(0)

  //用户B兑换代币
  await tokens[0].connect(other).approve(router.address, swapAmount)
  await router.connect(other).exactInput({
    recipient: wallet.address,
    deadline: 1,
    path: encodePath([tokens[0].address, tokens[2].address], [FeeAmount.MEDIUM]),
    amountIn: swapAmount,
    amountOutMinimum: 0,
  })
  
  //提取手续费
  const { amount0: other_nft1Amount0, amount1: other_nft1Amount1 } = await nft.connect(other).callStatic.collect({
    tokenId: 2,
    recipient: wallet.address,
    amount0Max: MaxUint128,
    amount1Max: MaxUint128,
  })
  expect(other_nft1Amount0).to.eq(2)
  expect(other_nft1Amount1).to.eq(0)
  
  await  advanceBlockTo(2101);

  expect(await tradeMint.pendingSumma(wallet.address)).to.equal("14814814814814814812")
  expect(await tradeMint.pendingSumma(other.address)).to.equal("0")

  //查看钱包余额
  expect(await tokens[0].balanceOf(wallet.address)).to.equal("57896044618658097711785492504343953926634992332820280019728792003956562818967")
  expect(await tokens[0].balanceOf(other.address)).to.equal("1999999999999999999999000")

  expect(await tokens[1].balanceOf(wallet.address)).to.equal("57896044618658097711785492504343953926634992332820280019728792003956563820963")
  expect(await tokens[1].balanceOf(other.address)).to.equal("2000000000000000000000000")

  expect(await summa.balanceOf(wallet.address)).to.equal("3200000000000000000")
  expect(await summa.balanceOf(other.address)).to.equal("0")

  
  //提出手续费
  await  tradeMint.connect(other).withdraw();
  await  tradeMint.connect(wallet).withdraw();
  
  //查看钱包余额
  expect(await tokens[0].balanceOf(wallet.address)).to.equal("57896044618658097711785492504343953926634992332820280019728792003956562818967")
  expect(await tokens[0].balanceOf(other.address)).to.equal("1999999999999999999999000")

  expect(await tokens[1].balanceOf(wallet.address)).to.equal("57896044618658097711785492504343953926634992332820280019728792003956563820963")
  expect(await tokens[1].balanceOf(other.address)).to.equal("2000000000000000000000000")

  expect(await summa.balanceOf(wallet.address)).to.equal("18014814814814814812")
  expect(await summa.balanceOf(other.address)).to.equal("0")
  console.log("summa balanceOf", ethers.utils.formatEther("3200000000000000000"));
  console.log("summa balanceOf",ethers.utils.formatEther("18014814814814814812"));
  
  const [token0, token1] = sortedTokens(tokens[0], tokens[1])
  const poolAddress = computePoolAddress(
    factory.address,
    [token0.address, token1.address,],
    FeeAmount.MEDIUM
  )

  expect(await tradeMint.getPendingSummaByTokenId(1)).to.equal("0")
  expect(await tradeMint.getPoolReward(poolAddress)).to.equal("44444444444444444439")



})




})
