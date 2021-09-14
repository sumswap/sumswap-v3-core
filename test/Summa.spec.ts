import { ethers } from 'hardhat'
import { expect } from './shared/expect'
import { Wallet } from 'ethers'
import { SummaTest, TestERC20 } from '../typechain'
import { randomBytes } from 'crypto'
import snapshotGasCost from './shared/snapshotGasCost'
import { advanceBlockTo ,mineBlock,latest} from './shared/time'

describe('Summa', () => {
  let summaTest: SummaTest
  let wallets: Wallet[]

  before('deploy test contract', async () => {
    summaTest = (await (await ethers.getContractFactory('SummaTest')).deploy()) as SummaTest
  })
  
  before('get wallets', async () => {
    wallets = await (ethers as any).getSigners()
  })

  it('blockTo 100', async () => {
    expect(await ethers.provider.getBlockNumber()).to.equal(1)
    await advanceBlockTo(100);
    expect(await ethers.provider.getBlockNumber()).to.equal(100)
    
    await advanceBlockTo(200);
    expect(await ethers.provider.getBlockNumber()).to.equal(200)

    await advanceBlockTo(300);
    expect(await ethers.provider.getBlockNumber()).to.equal(300)
  })
  
  describe('#Summa', () => {

    it("should have correct name and symbol and decimal and balanceOf", async function () {
      await advanceBlockTo(300);
      expect(await ethers.provider.getBlockNumber()).to.equal(300)

      const name = await summaTest.name()
      const symbol = await summaTest.symbol()
      const decimals = await summaTest.decimals()
      const balanceOf = await summaTest.balanceOf(wallets[0].address)
      expect(name, "SUM")
      expect(symbol, "SUM")
      expect(decimals, "18")
      expect(balanceOf, ethers.utils.parseEther("320000000").toString())
    })
  })
  
  // it("should only allow owner to mint token", async function () {
  //   await this.summaTest.mint(this.bob.address, "1000")
  //   await expect(this.sushi.connect(this.bob).mint(this.carol.address, "1000", { from: this.bob.address })).to.be.revertedWith(
  //     "Ownable: caller is not the owner"
  //   )
  //   const totalSupply = await this.sushi.totalSupply()
  //   const aliceBal = await this.sushi.balanceOf(this.alice.address)
  //   const bobBal = await this.sushi.balanceOf(this.bob.address)
  //   const carolBal = await this.sushi.balanceOf(this.carol.address)
  //   expect(totalSupply).to.equal("1100")
  //   expect(aliceBal).to.equal("100")
  //   expect(bobBal).to.equal("1000")
  //   expect(carolBal).to.equal("0")
  // })

})
