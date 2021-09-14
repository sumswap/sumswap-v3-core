import {
  abi as FACTORY_ABI,
  bytecode as FACTORY_BYTECODE,
} from '../../artifacts/contracts/mainContracts/SummaSwapV3Factory.sol/SummaSwapV3Factory.json'

// import { abi as FACTORY_V2_ABI, bytecode as FACTORY_V2_BYTECODE } from '../../artifacts/contracts/v2-core/UniswapV2Factory.sol/UniswapV2Factory.json'
import { Fixture } from 'ethereum-waffle'
import { ethers, waffle } from 'hardhat'
import { ISummaSwapV3Factory, IWETH9, MockTimeSwapRouter } from '../../typechain'

import WETH9 from '../../artifacts/contracts/mainContracts/WETH9.sol/WETH9.json'
import { Contract } from '@ethersproject/contracts'
import { constants } from 'ethers'

const wethFixture: Fixture<{ weth9: IWETH9 }> = async ([wallet]) => {
  const weth9 = (await waffle.deployContract(wallet, {
    bytecode: WETH9.bytecode,
    abi: WETH9.abi,
  })) as IWETH9

  return { weth9 }
}

// export const v2FactoryFixture: Fixture<{ factory: Contract }> = async ([wallet]) => {
//   const factory = await waffle.deployContract(
//     wallet,
//     {
//       bytecode: FACTORY_V2_BYTECODE,
//       abi: FACTORY_V2_ABI,
//     },
//     [constants.AddressZero]
//   )

//   return { factory }
// }

const v3CoreFactoryFixture: Fixture<ISummaSwapV3Factory> = async ([wallet]) => {
  return (await waffle.deployContract(wallet, {
    bytecode: FACTORY_BYTECODE,
    abi: FACTORY_ABI,
  })) as ISummaSwapV3Factory
}

export const v3RouterFixture: Fixture<{
  weth9: IWETH9
  factory: ISummaSwapV3Factory
  router: MockTimeSwapRouter
}> = async ([wallet], provider) => {
  const { weth9 } = await wethFixture([wallet], provider)
  const factory = await v3CoreFactoryFixture([wallet], provider)

  const router = (await (await ethers.getContractFactory('MockTimeSwapRouter')).deploy(
    factory.address,
    weth9.address
  )) as MockTimeSwapRouter

  return { factory, weth9, router }
}
