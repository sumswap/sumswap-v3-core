const { normalizeHardhatNetworkAccountsConfig } = require("hardhat/internal/core/providers/util")

const { BN, bufferToHex, privateToAddress, toBuffer } = require("ethereumjs-util")

module.exports = async function (taskArguments, hre, runSuper) {
  const accounts = await hre.ethers.getSigners();
  for (const [index, account] of accounts.entries()) {
    const address = account.address
    const privateKey = account.address
    const balance = new BN(account.balance).div(new BN(10).pow(new BN(18))).toString(10)
    console.log(`Account #${index}: ${address} (${balance} ETH)Private Key: ${privateKey}`)
  }
  
}