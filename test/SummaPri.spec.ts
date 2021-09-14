import { ethers } from 'hardhat'
import { expect } from './shared/expect'
import { SummaPriTest, TestERC20 } from '../typechain'
import { randomBytes } from 'crypto'
import snapshotGasCost from './shared/snapshotGasCost'

describe('SummaPri', () => {
  let summaPri: SummaPriTest
  before('deploy test contract', async () => {
    summaPri = (await (await ethers.getContractFactory('SummaPriTest')).deploy()) as SummaPriTest
  })

  describe('#inviteCompetition', () => {
   
  })
})
