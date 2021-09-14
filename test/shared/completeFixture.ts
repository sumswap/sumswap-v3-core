import { Fixture } from 'ethereum-waffle'
import { ethers } from 'hardhat'
import { v3RouterFixture } from './externalFixtures'
import { constants } from 'ethers'
import {
  Summa,
  TokenIssue,
  SummaPri,
  TradeMint,
  IWETH9,
  MockTimeSummaSwapV3Manager,
  MockTimeSwapRouter,
  SummaSwapV3NFTDescriptor,
  TestERC20,
  ISummaSwapV3Factory,
  Quoter
} from '../../typechain'

const completeFixture: Fixture<{
  summa: Summa
  tokenIssue: TokenIssue
  summaPri: SummaPri
  tradeMint: TradeMint
  weth9: IWETH9
  factory: ISummaSwapV3Factory
  quoter: Quoter
  router: MockTimeSwapRouter
  nft: MockTimeSummaSwapV3Manager
  nftDescriptor: SummaSwapV3NFTDescriptor
  tokens: [TestERC20, TestERC20, TestERC20]

}> = async ([wallet], provider) => {
  const SummaTest = await ethers.getContractFactory('SummaTest')
  const summa = (await SummaTest.deploy()) as Summa
  
  const SummaPriTest = await ethers.getContractFactory('SummaPriTest')
  const summaPri = (await SummaPriTest.deploy(summa.address)) as SummaPri
  
  const TokenIssueTest = await ethers.getContractFactory('TokenIssueTest')
  const tokenIssue = (await TokenIssueTest.deploy(summa.address,summaPri.address)) as TokenIssue

  const TradeMintTest = await ethers.getContractFactory('TradeMintTest')
  const tradeMint = (await TradeMintTest.deploy()) as TradeMint

  await summa.updateSummaPri(summaPri.address);
  await summa.updateTokenIssue(tokenIssue.address);

  const { weth9, factory, router } = await v3RouterFixture([wallet], provider)
  const tokenFactory = await ethers.getContractFactory('TestERC20')
  const tokens: [TestERC20, TestERC20, TestERC20] = [
    (await tokenFactory.deploy(ethers.utils.parseEther("100000"),"USDT","USDT")) as TestERC20, // do not use maxu256 to avoid overflowing
    (await tokenFactory.deploy(ethers.utils.parseEther("100000"),"ETH","ETH")) as TestERC20,
    (await tokenFactory.deploy(ethers.utils.parseEther("100000"),"SUM","SUM")) as TestERC20,
  ]
  const quoterFactory = await ethers.getContractFactory('Quoter')
  const quoter = (await quoterFactory.deploy(factory.address, weth9.address)) as Quoter


  const nftDescriptorLibraryFactory = await ethers.getContractFactory('NFTDescriptor')
  const nftDescriptorLibrary = await nftDescriptorLibraryFactory.deploy()
  const positionDescriptorFactory = await ethers.getContractFactory('SummaSwapV3NFTDescriptor', {
    libraries: {
      NFTDescriptor: nftDescriptorLibrary.address,
    },
  })
  const nftDescriptor = (await positionDescriptorFactory.deploy(
    weth9.address
  )) as SummaSwapV3NFTDescriptor

  const positionManagerFactory = await ethers.getContractFactory('MockTimeSummaSwapV3Manager')
  const nft = (await positionManagerFactory.deploy(
    factory.address,
    weth9.address,
    nftDescriptor.address
  )) as MockTimeSummaSwapV3Manager

  tokens.sort((a, b) => (a.address.toLowerCase() < b.address.toLowerCase() ? -1 : 1))
  
  await tokenIssue.setStart();
  await tokenIssue.set
  await summaPri.grantRole("0xcad07eb0533b96601ccc07ce1242e3fd31f6e7058c200d3a8c45917679cede7f", tradeMint.address);

  await tradeMint.setTokenIssue(tokenIssue.address);
  await tradeMint.setSummaAddress(summa.address);
  await tradeMint.setISummaSwapV3Manager(nft.address);
  await tradeMint.setTotalIssueRate(2000);
  await tradeMint.setSettlementBlock(50);
  await tradeMint.setFactory(factory.address);
  await tradeMint.setTradeShare(4);
  await tradeMint.setPledgeRate(0);
  await tradeMint.setMinPledge(0);
  await tradeMint.setPriAddress(summaPri.address);
  await tradeMint.setReduceFee(4);
  await tradeMint.setSuperFee(5);

  await factory.setTradeMintAddress(tradeMint.address);

  return {
    summa,
    tokenIssue,
    summaPri,
    tradeMint,
    weth9,
    factory,
    router,
    tokens,
    nft,
    nftDescriptor,
    quoter
  }
}

export default completeFixture
