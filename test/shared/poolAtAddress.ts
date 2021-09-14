import { abi as POOL_ABI } from '../../artifacts/contracts/mainContracts/SummaSwapV3Pool.sol/SummaSwapV3Pool.json'
import { Contract, Wallet } from 'ethers'
import { ISummaSwapV3Pool } from '../../typechain'

export default function poolAtAddress(address: string, wallet: Wallet): ISummaSwapV3Pool {
  return new Contract(address, POOL_ABI, wallet) as ISummaSwapV3Pool
}
