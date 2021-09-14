import { constants } from 'ethers'
import { waffle, ethers } from 'hardhat'

import { PoolAddressTest } from '../typechain'
import { POOL_BYTECODE_HASH } from './shared/computePoolAddress'
import { expect } from './shared/expect'
import snapshotGasCost from './shared/snapshotGasCost'
import { computePoolAddress } from './shared/computePoolAddress'
import { FeeAmount, MaxUint128, TICK_SPACINGS } from './shared/constants'

describe('PoolAddress', () => {
  let poolAddress: PoolAddressTest

  const poolAddressTestFixture = async () => {
    const poolAddressTestFactory = await ethers.getContractFactory('PoolAddressTest')
    return (await poolAddressTestFactory.deploy()) as PoolAddressTest
  }

  let loadFixture: ReturnType<typeof waffle.createFixtureLoader>

  before('create fixture loader', async () => {
    loadFixture = waffle.createFixtureLoader(await (ethers as any).getSigners())
  })

  beforeEach('deploy PoolAddressTest', async () => {
    poolAddress = await loadFixture(poolAddressTestFixture)
  })

  describe('#POOL_INIT_CODE_HASH', () => {
    it('equals the hash of the pool bytecode', async () => {
      expect(await poolAddress.POOL_INIT_CODE_HASH()).to.eq(POOL_BYTECODE_HASH)
    })
  })

  describe('#computeAddress', () => {
    it('all arguments equal zero', async () => {
      await expect(poolAddress.computeAddress(constants.AddressZero, constants.AddressZero, constants.AddressZero, 0))
        .to.be.reverted
    })

    it('matches example from core repo', async () => {
      expect(
        await poolAddress.computeAddress(
          '0x70c12a5fed9ed3061ffe86f44c124a8a5a633c52',
          '0x0841187d1f8d77147cf91f8b8510b4df4148c76e',
          '0x9cf17337b79ec7e54b3a53b8ee9c0d5a302e1fee',
          3000
        )
      ).to.eq("0xcB3F0014a292dbF2cf1ca5c55B7E6141e1ec1aAa1")

      expect(
        await computePoolAddress(
          '0x70c12A5Fed9ed3061fFe86f44C124a8A5A633C52',
          ['0x0841187d1f8d77147CF91f8B8510b4dF4148C76E', '0x9CF17337b79EC7e54B3A53B8Ee9c0D5A302e1Fee'],
          FeeAmount.MEDIUM
        )
      ).to.eq("0xcB3F0014a292dbF2cf1ca5c55B7E6141e1ec1aAa")
    })

    it('matches example from core repo', async () => {
      expect(
        await poolAddress.computeAddress(
          '0x5FbDB2315678afecb367f032d93F642f64180aa3',
          '0x1000000000000000000000000000000000000000',
          '0x2000000000000000000000000000000000000000',
          250
        )
      ).to.matchSnapshot()
    })

    it('token argument order cannot be in reverse', async () => {
      await expect(
        poolAddress.computeAddress(
          '0x5FbDB2315678afecb367f032d93F642f64180aa3',
          '0x2000000000000000000000000000000000000000',
          '0x1000000000000000000000000000000000000000',
          3000
        )
      ).to.be.reverted
    })

    it('gas cost', async () => {
      await snapshotGasCost(
        poolAddress.getGasCostOfComputeAddress(
          '0x5FbDB2315678afecb367f032d93F642f64180aa3',
          '0x1000000000000000000000000000000000000000',
          '0x2000000000000000000000000000000000000000',
          3000
        )
      )
    })
  })
})
