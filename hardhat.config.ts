import 'hardhat-typechain';
import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-waffle';
import '@nomiclabs/hardhat-etherscan';
import dotenv from 'dotenv';
import { task } from 'hardhat/config';
import "hardhat-spdx-license-identifier"
require('hardhat-contract-sizer');
import "./tasks/index.js"

import { keccak256 } from '@ethersproject/solidity';
import {
  allowVerifyChain,
  compileSetting,
  deployContract,
  getContract,
  mainTokenName,
} from './script/deployTool';
import { RPCS } from './script/network';

const defaultAccount = 3;

dotenv.config();

task("accounts", "Prints the list of accounts", async (taskArgs, bre) => {
  const accounts = await bre.ethers.getSigners();

  for (const account of accounts) {
    let address = await account.getAddress();
    console.log(
      address,
      (await bre.ethers.provider.getBalance(address)).toString()
    );
  }
});

task("getHash", "Get INIT_CODE_HASH").setAction(
  async ({}, { ethers, run, network }) => {
    await run("compile");
    const signer = (await ethers.getSigners())[defaultAccount];
    console.log("V3 signer:", signer);
    // const v2factory = await ethers.getContractFactory("UniswapV2Factory");
    // const v2pair = await ethers.getContractFactory("UniswapV2Pair");
    const v3factory = await ethers.getContractFactory("SummaSwapV3Factory");
    const v3pool = await ethers.getContractFactory("SummaSwapV3Pool");

    // const v2bytecode = v2pair.bytecode;
    const v3bytecode = v3pool.bytecode;

    // const COMPUTED_V2_INIT_CODE_HASH = keccak256(["bytes"], [v2bytecode]);
    const COMPUTED_V3_INIT_CODE_HASH = keccak256(["bytes"], [v3bytecode]);

    // console.log("COMPUTED_V2_INIT_CODE_PAIR_HASH:", COMPUTED_V2_INIT_CODE_HASH);
    console.log("COMPUTED_V3_POOL_INIT_CODE_HASH:", COMPUTED_V3_INIT_CODE_HASH);

    // const v2contract = await v2factory.deploy(signer.address);
    const v3contract = await v3factory.deploy();

    // await v2contract.deployTransaction.wait();
    await v3contract.deployTransaction.wait();
    // const v2hash = await v2contract.INIT_CODE_PAIR_HASH();
    const v3hash = await v3contract.POOL_INIT_CODE_HASH();

    // console.log("V2 INIT_CODE_PAIR_HASH:", v2hash);
    console.log("V3 POOL_INIT_CODE_HASH:", v3hash);
  }
);

task("deploy", "deploy contract")
  .addParam("contract", "the contract name")
  .setAction(async ({ contract }, { ethers, run, network }) => {
    await run("compile");
    const signers = await ethers.getSigners();

    const contractInstant = await deployContract(
      contract,
      network.name,
      ethers.getContractFactory,
      signers[defaultAccount]
    );
  });

task("deployV2", "deploy V2 contracts")
  .addOptionalParam("weth9", "the WETH9 address")
  .setAction(async ({ weth9 }, { ethers, run, network }) => {
    await run("compile");
    const signer = (await ethers.getSigners())[defaultAccount];

    console.log("Signer", signer.address);
    console.log(
      "getBalance",
      (await ethers.provider.getBalance(signer.address)).toString()
    );

    console.log("Network On:", network.name);

    if (weth9 == undefined) {
      const WETH9 = await deployContract(
        "WETH9",
        network.name,
        ethers.getContractFactory,
        signer
      );

      if (allowVerifyChain.indexOf(network.name) > -1) {
        await run("verify:verify", {
          address: WETH9.address,
        });
      }
      weth9 = WETH9.address;
    }

    const UniswapV2Factory = await deployContract(
      "UniswapV2Factory",
      network.name,
      ethers.getContractFactory,
      signer,
      [signer.address]
    );

    const UniswapV2Router02 = await deployContract(
      "UniswapV2Router02",
      network.name,
      ethers.getContractFactory,
      signer,
      [UniswapV2Factory.address, weth9]
    );
});


task("deployUsdt", "deploy TetherToken USDT")
  //0xB3ACF8794D4Fb214809e322a10DcfE648445e6cD
  .setAction(async ({}, { ethers, run, network }) => {
    await run("compile");
    const signer = (await ethers.getSigners())[defaultAccount];

    console.log("Signer", signer.address);
    console.log(
      "getBalance",
      (await ethers.provider.getBalance(signer.address)).toString()
    );
       
    console.log("Network On:", network.name);
    const TetherToken = await deployContract(
      "TetherToken",
      network.name,
      ethers.getContractFactory,
      signer,
      [ethers.utils.parseUnits("100000000000000000000","mwei"),"TetherToken","USDT",6]
    );
      
});
task("deployToken", "deploy Token USDT")
  .setAction(async ({}, { ethers, run, network }) => {
    await run("compile");
    const signer = (await ethers.getSigners())[defaultAccount];

    console.log("Signer", signer.address);
    console.log(
      "getBalance",
      (await ethers.provider.getBalance(signer.address)).toString()
    );
       
    console.log("Network On:", network.name);
    let deployAddress = [];
    // const Token = await deployContract(
    //   "Token",
    //   network.name,
    //   ethers.getContractFactory,
    //   signer,
    //   ["AAVE","AAVE"]
    // );
    // deployAddress.push({"AAVE":Token.address});
    // const Token1 = await deployContract(
    //   "Token",
    //   network.name,
    //   ethers.getContractFactory,
    //   signer,
    //   ["BNB","BNB"]
    // );
    // deployAddress.push({"BNB":Token1.address});
    // const Token2 = await deployContract(
    //   "Token",
    //   network.name,
    //   ethers.getContractFactory,
    //   signer,
    //   ["HEX","HEX"]
    // );
    // deployAddress.push({"HEX":Token2.address});
    // const Token3 = await deployContract(
    //   "Token",
    //   network.name,
    //   ethers.getContractFactory,
    //   signer,
    //   ["LINK","LINK"]
    // );
    // deployAddress.push({"LINK":Token3.address});
    // const Token4 = await deployContract(
    //   "Token",
    //   network.name,
    //   ethers.getContractFactory,
    //   signer,
    //   ["VEN","VEN"]
    // );
    // deployAddress.push({"VEN":Token4.address});
    // const Token5 = await deployContract(
    //   "Token",
    //   network.name,
    //   ethers.getContractFactory,
    //   signer,
    //   ["TRX","TRX"]
    // );
    // deployAddress.push({"TRX":Token5.address});
    // const Token6 = await deployContract(
    //   "Token",
    //   network.name,
    //   ethers.getContractFactory,
    //   signer,
    //   ["GRT","GRT"]
    // );
    // deployAddress.push({"GRT":Token6.address});
    const Token7 = await deployContract(
      "Token",
      network.name,
      ethers.getContractFactory,
      signer,
      ["BTM","BTM"]
    );
    deployAddress.push({"BTM":Token7.address});
    console.log(deployAddress);
});
task("verifyToken", "verify Token contracts")
  .setAction(async ({ weth9 }, { ethers, run, network }) => {
    if (allowVerifyChain.indexOf(network.name) > -1) {
    
    var num:number = 8; 
    var i:number; 

 
    for(i = num;i<=num;i++) {
        await run("verify:verify", getContract(network.name, "Token"));
      }
    }
  });
  task("verifyUSDTToken", "verify USDT contracts")
  .setAction(async ({ weth9 }, { ethers, run, network }) => {
    if (allowVerifyChain.indexOf(network.name) > -1) {
    
      await run("verify:verify", getContract(network.name, "TetherToken"));
    }
  });

task("deployV3", "deploy V3 contracts")
  .addOptionalParam("weth9", "the WETH9 address")
  .setAction(async ({ weth9 }, { ethers, run, network }) => {
    await run("compile");
    const signer = (await ethers.getSigners())[defaultAccount];

    console.log("Signer", signer.address);
    console.log(
      "getBalance",
      (await ethers.provider.getBalance(signer.address)).toString()
    );
    
    let deployAddress = [];

    // const Summa = await deployContract(
    //   "Summa",
    //   network.name,
    //   ethers.getContractFactory,
    //   signer,
    //   ["320000000000000000000000000"]
    // );
    // deployAddress.push({"Summa":Summa.address});  
    
    // const SummaPri = await deployContract(
    //   "SummaPri",
    //   network.name,
    //   ethers.getContractFactory,
    //   signer,
    //   [Summa.address]
    // );
    // deployAddress.push({"SummaPri":SummaPri.address});  
    
    const SummaSwapInterfaceMulticall = await deployContract(
      "SummaSwapInterfaceMulticall",
      network.name,
      ethers.getContractFactory,
      signer
    );
    deployAddress.push({"SummaSwapInterfaceMulticall":SummaSwapInterfaceMulticall.address});  
       
    weth9 = "0xc778417E063141139Fce010982780140Aa0cD5Ab";
    // if (weth9 == "" || weth9 == null) {
    //   const WETH9 = await deployContract(
    //     "WETH9",
    //     network.name,
    //     ethers.getContractFactory,
    //     signer
    //   );
    //   //await run("verify:verify", { address: weth9 });
    //   weth9 = WETH9.address;
    // }
    deployAddress.push({"WETH9":weth9});  

    const SummaSwapV3Factory = await deployContract(
      "SummaSwapV3Factory",
      network.name,
      ethers.getContractFactory,
      signer
    );
    deployAddress.push({"SummaSwapV3Factory":SummaSwapV3Factory.address});  
    
    // const v3hash = await SummaSwapV3Factory.POOL_INIT_CODE_HASH();
    // console.log("V3 POOL_INIT_CODE_HASH:", v3hash);

    // const TickLens = await deployContract(
    //   "TickLens",
    //   network.name,
    //   ethers.getContractFactory,
    //   signer
    // );
    // deployAddress.push({"TickLens":TickLens.address});  

    const Quoter = await deployContract(
      "Quoter",
      network.name,
      ethers.getContractFactory,
      signer,
      [SummaSwapV3Factory.address, weth9]
    );
    deployAddress.push({"Quoter":Quoter.address});  

    const SummaSwapV3Router = await deployContract(
      "SummaSwapV3Router",
      network.name,
      ethers.getContractFactory,
      signer,
      [SummaSwapV3Factory.address, weth9]
    );
    deployAddress.push({"SummaSwapV3Router":SummaSwapV3Router.address});  

    const NFTDescriptor = await deployContract(
      "NFTDescriptor",
      network.name,
      ethers.getContractFactory,
      signer
    );
    deployAddress.push({"NFTDescriptor":NFTDescriptor.address});  

    const SummaSwapV3NFTDescriptor = await deployContract(
      "SummaSwapV3NFTDescriptor",
      network.name,
      ethers.getContractFactory,
      signer,
      [weth9],
      {
        "NFTDescriptor":
          NFTDescriptor.address,
      }
    );
    deployAddress.push({"SummaSwapV3NFTDescriptor":SummaSwapV3NFTDescriptor.address});  
    
    // const ProxyAdmin = await deployContract(
    //   "contracts/upgrades/ProxyAdmin/ProxyAdmin.sol:ProxyAdmin",
    //   network.name,
    //   ethers.getContractFactory,
    //   signer
    // );
    // deployAddress.push({"ProxyAdmin":ProxyAdmin.address});  

    // const TransparentUpgradeableProxy = await deployContract(
    //   "contracts/upgrades/TransparentUpgradeableProxy/TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy",
    //   network.name,
    //   ethers.getContractFactory,
    //   signer,
    //   [SummaSwapV3NFTDescriptor.address, ProxyAdmin.address, "0x"]
    // );
    // deployAddress.push({"TransparentUpgradeableProxy":TransparentUpgradeableProxy.address});  
    

    const SummaSwapV3Manager = await deployContract(
      "SummaSwapV3Manager",
      network.name,
      ethers.getContractFactory,
      signer,
      [SummaSwapV3Factory.address, weth9, SummaSwapV3NFTDescriptor.address]
    );
    deployAddress.push({"SummaSwapV3Manager":SummaSwapV3Manager.address}); 
    

    const TradeMint = await deployContract(
      "TradeMint",
      network.name,
      ethers.getContractFactory,
      signer,
    );
    deployAddress.push({"TradeMint":TradeMint.address});  

    const V3Migrator = await deployContract(
      "V3Migrator",
      network.name,
      ethers.getContractFactory,
      signer,
      [SummaSwapV3Factory.address, weth9, SummaSwapV3Manager.address]
    );
    deployAddress.push({"V3Migrator":V3Migrator.address});  
    
    console.log(deployAddress);
      
    //设置合约相关方法
    // await  TradeMint.setTokenIssue("0xE4454EA3EA1e08F089c4a66aed0CC3f1054093Da");
    // const tokenIssue = await   TradeMint.tokenIssue();
    // console.log("TradeMint.tokenIssue " ,tokenIssue);
    // await  TradeMint.setISummaSwapV3Manager("0x2Bad6ABe63F3786aFC06F025dA3190754d8dE8B1");
    // const iSummaSwapV3Manager = await   TradeMint.iSummaSwapV3Manager();
    // console.log("TradeMint.iSummaSwapV3Manager " ,iSummaSwapV3Manager);
    await  TradeMint.setTotalIssueRate(2000);
    const totalIssueRate = await   TradeMint.totalIssueRate();
    console.log("TradeMint.totalIssueRate " ,totalIssueRate);
    
    await  TradeMint.setSettlementBlock(50);
    const settlementBlock = await   TradeMint.settlementBlock();
    console.log("TradeMint.settlementBlock " ,settlementBlock);

    // await  TradeMint.setFactory("0x6B5a3f0deD265bfDC4F437aA8d4C5dB42DEbA849");
    // const factory = await   TradeMint.factory();
    // console.log("TradeMint.factory " ,factory);

    await  TradeMint.setTradeShare(4);
    const tradeShare = await   TradeMint.tradeShare();
    console.log("TradeMint.tradeShare " ,tradeShare);

    // await  TradeMint.setSummaAddress("0x70d1F33cA9dce93Cf1011d20b975A352e01687AD");
    // const summaAddress = await   TradeMint.summaAddress();
    // console.log("TradeMint.summaAddress " ,summaAddress);

    // await  TradeMint.setPriAddress("0x26D71Bb4be30F195492826F575d9beB834FF850C");
    // const priAddress = await   TradeMint.priAddress();
    // console.log("TradeMint.priAddress " ,priAddress);

    await  TradeMint.setReduceFee(4);
    const reduceFee = await   TradeMint.reduceFee();
    console.log("TradeMint.reduceFee " ,reduceFee);

    await  TradeMint.setSuperFee(5);
    const superFee = await   TradeMint.superFee();
    console.log("TradeMint.superFee " ,superFee);

});

task("deployTradeMint", "deploy TradeMint contracts")
  .setAction(async ({ weth9 }, { ethers, run, network }) => {
    await run("compile");
    const signer = (await ethers.getSigners())[defaultAccount];
    console.log("Signer", signer.address);
    console.log(
      "getBalance",
      (await ethers.provider.getBalance(signer.address)).toString()
    );
    let deployAddress = [];
    const TradeMint = await deployContract(
      "TradeMint",
      network.name,
      ethers.getContractFactory,
      signer,
    );
    deployAddress.push({"TradeMint":TradeMint.address});  
    console.log(deployAddress);
    await  TradeMint.setTokenIssue("0xdDb5115bDA18dFA4580A72753F896c641c080C5C");
    const tokenIssue = await   TradeMint.tokenIssue();
    console.log("TradeMint.tokenIssue " ,tokenIssue);
    await  TradeMint.setISummaSwapV3Manager("0x94ECa10eB8D209a36ca65898f2d4925687F1e273");
    const iSummaSwapV3Manager = await   TradeMint.iSummaSwapV3Manager();
    console.log("TradeMint.iSummaSwapV3Manager " ,iSummaSwapV3Manager);
    await  TradeMint.setTotalIssueRate(2000);
    const totalIssueRate = await   TradeMint.totalIssueRate();
    console.log("TradeMint.totalIssueRate " ,totalIssueRate);

    await  TradeMint.setSettlementBlock(50);
    const settlementBlock = await   TradeMint.settlementBlock();
    console.log("TradeMint.settlementBlock " ,settlementBlock);

    await  TradeMint.setFactory("0x039c883Fe9ac6a4757bdc8Bfa83586139c123a3C");
    const factory = await   TradeMint.factory();
    console.log("TradeMint.factory " ,factory);

    await  TradeMint.setTradeShare(4);
    const tradeShare = await   TradeMint.tradeShare();
    console.log("TradeMint.tradeShare " ,tradeShare);

    await  TradeMint.setSummaAddress("0xd6b34C35EBE40acC0679aE2151D4f30411C29046");
    const summaAddress = await   TradeMint.summaAddress();
    console.log("TradeMint.summaAddress " ,summaAddress);

    await  TradeMint.setPriAddress("0x3f8767d4816D779088f1e46fF3f8A77Bf95f27cE");
    const priAddress = await   TradeMint.priAddress();
    console.log("TradeMint.priAddress " ,priAddress);

    await  TradeMint.setReduceFee(4);
    const reduceFee = await   TradeMint.reduceFee();
    console.log("TradeMint.reduceFee " ,reduceFee);

    await  TradeMint.setSuperFee(5);
    const superFee = await   TradeMint.superFee();
    console.log("TradeMint.superFee " ,superFee);

    console.log(deployAddress);
});
task("verifyTradeMint", "verify TradeMint contracts")
  .setAction(async ({ weth9 }, { ethers, run, network }) => {
    if (allowVerifyChain.indexOf(network.name) > -1) {
      await run("verify:verify", getContract(network.name, "TradeMint"));
    }
  });
task("verifyV2", "verify V2 contracts")
  .addParam("weth9", "the WETH9 address")
  .setAction(async ({ weth9 }, { ethers, run, network }) => {
    if (allowVerifyChain.indexOf(network.name) > -1) {
      await run("verify:verify", getContract(network.name, "UniswapV2Factory"));
      await run(
        "verify:verify",
        getContract(network.name, "UniswapV2Router02")
      );
    }
  });
task("verifyV3", "verify V3 contracts")
  .setAction(async ({ weth9 }, { ethers, run, network }) => {
    if (allowVerifyChain.indexOf(network.name) > -1) {
      await run("verify:verify", getContract(network.name, "SummaSwapInterfaceMulticall"));
      await run("verify:verify", getContract(network.name, "SummaSwapV3Factory"));
      // await run("verify:verify", getContract(network.name, "TickLens"));
      await run("verify:verify", getContract(network.name, "Quoter"));
      await run("verify:verify", getContract(network.name, "SummaSwapV3Router"));
      await run("verify:verify", getContract(network.name, "NFTDescriptor"));
      await run("verify:verify", getContract(network.name, "TradeMint"));
      await run(
        "verify:verify",
        getContract(network.name, "SummaSwapV3NFTDescriptor")
      );
      // await run("verify:verify", getContract(network.name, "ProxyAdmin"));
      await run(
        "verify:verify",
        getContract(network.name, "TradeMint")
      );
      await run(
        "verify:verify",
        getContract(network.name, "SummaSwapV3Manager")
      );
      await run("verify:verify", getContract(network.name, "V3Migrator"));
    }
  });
task("deploySummaV2", "deploy SummaV2 contracts")
  .setAction(async ({ weth9 }, { ethers, run, network }) => {
    await run("compile");
    const signer = (await ethers.getSigners())[defaultAccount];
    console.log("Signer", signer.address);
    console.log(
      "getBalance",
      (await ethers.provider.getBalance(signer.address)).toString()
    );
    let deployAddress = [];
    const Summa = await deployContract(
      "Summa",
      network.name,
      ethers.getContractFactory,
      signer,
      ['32000000000000000000000000']
    );
    deployAddress.push({"Summa":Summa.address});
    const SummaPri = await deployContract(
      "SummaPri",
      network.name,
      ethers.getContractFactory,
      signer,
      [Summa.address]
    );
    deployAddress.push({"SummaPri":SummaPri.address}); 
    const TokenIssue = await deployContract(
      "TokenIssue",
      network.name,
      ethers.getContractFactory,
      signer,
      [Summa.address,SummaPri.address]
    );
    deployAddress.push({"TokenIssue":TokenIssue.address});  
    console.log(deployAddress);
});
task("verifySummaV2", "verify SummaV2 contracts")
  .setAction(async ({ weth9 }, { ethers, run, network }) => {
    if (allowVerifyChain.indexOf(network.name) > -1) {
      await run("verify:verify", getContract(network.name, "Summa"));
      await run("verify:verify", getContract(network.name, "SummaPri"));
      await run("verify:verify", getContract(network.name, "TokenIssue"));
    }
});
export default {
  networks: RPCS,
  defaultNetwork: "hardhat",
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: true,
    disambiguatePaths: false,
  },
  spdxLicenseIdentifier: {
    overwrite: true,
    runOnCompile: true,
  },
  solidity: {
    compilers: [compileSetting("0.7.6", 100)],
    overrides: {
      "contracts/mainContracts/WETH9.sol": compileSetting("0.4.19", 200),
      "contracts/mainContracts/TetherToken.sol": compileSetting("0.4.17", 200),

      "contracts/SummaV2/Summa.sol": compileSetting("0.6.12", 200),
      "contracts/SummaV2/SummaPri.sol": compileSetting("0.6.12", 200),
      "contracts/SummaV2/TokenIssue.sol": compileSetting("0.6.12", 200),
      "contracts/SummaV2/interface/ISummaPri.sol": compileSetting("0.6.12", 999_999),
      "contracts/SummaV2/interface/IAccessControl.sol": compileSetting(
        "0.6.12",
        200
      ),
      "contracts/SummaV2/interface/ISumma.sol": compileSetting(
        "0.6.12",
        200
      ),
      // "contracts/Multicall2/UniswapInterfaceMulticall.sol": compileSetting("0.7.6", 200),
      // "contracts/ProxyAdmin/ProxyAdmin.sol": compileSetting("0.7.4", 200),
      // "contracts/TickLens/TickLens.sol": compileSetting("0.7.6", 200),
      // "contracts/TickLens/Quoter.sol": compileSetting("0.7.6", 1_000_000),
      // "contracts/TickLens/SwapRouter.sol": compileSetting("0.7.6", 1_000_000),
      // "contracts/NFTDescriptor/NFTDescriptor.sol": compileSetting("0.7.6", 200),
      // "contracts/NonfungibleTokenPositionDescriptor/NonfungibleTokenPositionDescriptor.sol":
      //   compileSetting("0.7.6", 1_000),
      // "contracts/TransparentUpgradeableProxy/TransparentUpgradeableProxy.sol":
      //   compileSetting("0.7.4", 200),
      // "contracts/NonfungiblePositionManager/NonfungiblePositionManager.sol":
      //   compileSetting("0.7.6", 2_000),
      //"contracts/V3Migrator/V3Migrator.sol": compileSetting("0.7.6", 1_000_000),
    },
  },
};
