const { task } = require("hardhat/config")
// task("accounts", "Prints the list of accounts", require("./accounts"))
// import { decodePath, encodePath } from '../test/shared/path'
// import { FeeAmount } from '../test/constants'

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


task("usdt", "deploy TetherToken USDT")
  .setAction(async ({}, { ethers, run, network }) => {
    const TetherToken = await ethers.getContractFactory("TetherToken")
    const token = TetherToken.attach("0xB3ACF8794D4Fb214809e322a10DcfE648445e6cD")
    
    const totalSupply  = await token.totalSupply();
    console.log("token.name ", await token.name());
    //console.log("token.totalSupply ",ethers.utils.formatEher(totalSupply.toString()).toString());
});


// task("rswapusdt", "Prints swap", async (taskArgs, bre) => {
//   const swapAmount = 10;//bre.ethers.utils.parseUnits("0.0001","mwei");
//   let tokens =  ["0xB3ACF8794D4Fb214809e322a10DcfE648445e6cD", "0xF8c548cC3398884FF77373F4e975D1E601Fd5bAE"]
//   let router = "0x7CA52848D74bC958C0bEc702075EcE329c186719"
//   let deadline = Math.round(new Date() / 1000)  +  600
//   const accounts = await bre.ethers.getSigners();
//   let LOW = 10000
  
//   const TetherToken = await ethers.getContractFactory("TetherToken")
//   const tetherToken = TetherToken.attach(tokens[0])
//   //await tetherToken.approve(router, swapAmount)

//   const SummaSwapV3Router = await ethers.getContractFactory("SummaSwapV3Router")
//   const summaSwapV3Router = SummaSwapV3Router.attach(router)

//     let address = await accounts[0].getAddress();
    
//   console.log(deadline);
//   console.log(address);

//   const tx =  await summaSwapV3Router.exactInput({
//     recipient: address,
//     deadline: deadline,
//     //path: encodePath([tokens[0], tokens[1]], [LOW]),
//     path: "0xb3acf8794d4fb214809e322a10dcfe648445e6cd002710f8c548cc3398884ff77373f4e975d1e601fd5bae",
//     amountIn: swapAmount,
//     amountOutMinimum: 0,
//   })
//   console.log("swap  tx  ", tx);

// });


// task("rswapsum", "Prints swap", async (taskArgs, bre) => {
//   const swapAmount = 100;//bre.ethers.utils.parseUnits("0.0001","mwei");
//   let tokens =  ["0xB3ACF8794D4Fb214809e322a10DcfE648445e6cD", "0xf8c548cc3398884ff77373f4e975d1e601fd5bae"]
//   let router = "0x7CA52848D74bC958C0bEc702075EcE329c186719"
//   let deadline = Math.round(new Date() / 1000)  +  600
//   const accounts = await bre.ethers.getSigners();
//   let LOW = 500
  
//   const TetherToken = await ethers.getContractFactory("TetherToken")
//   const tetherToken = TetherToken.attach(tokens[0])
//   //await tetherToken.approve(router, swapAmount)

//   const SummaSwapV3Router = await ethers.getContractFactory("SummaSwapV3Router")
//   const summaSwapV3Router = SummaSwapV3Router.attach(router)

//   let address = await accounts[0].getAddress();
  
//   console.log(deadline);
//   console.log(address);

//   const tx =  await summaSwapV3Router.exactInputSingle({
//     tokenIn: "0xF8c548cC3398884FF77373F4e975D1E601Fd5bAE",
//     tokenOut:	"0xB3ACF8794D4Fb214809e322a10DcfE648445e6cD",
//     recipient: "0x0b40a188D28F8cF561Ad7B665dfb0f3D3b77BffF",
//     deadline:	deadline,
//     amountIn:	100000000000000,
//     fee: 10000,
//     amountOutMinimum:	0,
//     sqrtPriceLimitX96: 0,
//   })
//   console.log("swap  tx  ", tx);

// });


// usdt 0xe1F20070227eaCFC2C60d9f50aD0d99694550F6C

// task("rswapusdt", "Prints swap", async (taskArgs, bre) => {
//   const swapAmount = 100;//bre.ethers.utils.parseUnits("0.0001","mwei");
//   let tokens =  ["0xB3ACF8794D4Fb214809e322a10DcfE648445e6cD", "0xF8c548cC3398884FF77373F4e975D1E601Fd5bAE"]
//   let router = "0x7CA52848D74bC958C0bEc702075EcE329c186719"
//   let deadline = Math.round(new Date() / 1000)  +  600
//   const accounts = await bre.ethers.getSigners();
//   let LOW = 500
  
//   const TetherToken = await ethers.getContractFactory("TetherToken")
//   const tetherToken = TetherToken.attach(tokens[0])
//   //await tetherToken.approve(router, swapAmount)

//   const SummaSwapV3Router = await ethers.getContractFactory("SummaSwapV3Router")
//   const summaSwapV3Router = SummaSwapV3Router.attach(router)

//   let address = await accounts[0].getAddress();
  
//   console.log(deadline);
//   console.log(address);

//   const tx =  await summaSwapV3Router.exactInputSingle({
//     tokenIn: "0xB3ACF8794D4Fb214809e322a10DcfE648445e6cD",
//     tokenOut:	"0xF8c548cC3398884FF77373F4e975D1E601Fd5bAE",
//     recipient: "0x0b40a188D28F8cF561Ad7B665dfb0f3D3b77BffF",
//     deadline:	deadline,
//     amountIn:	10,
//     fee: 500,
//     amountOutMinimum:	0,
//     sqrtPriceLimitX96: 0,
//   })
//   console.log("swap  tx  ", tx);

//   // const tx =  await summaSwapV3Router.exactInput({
//   //   recipient: address,
//   //   deadline: deadline,
//   //   //path: encodePath([tokens[0], tokens[1]], [LOW]),
//   //   path: "0xb3acf8794d4fb214809e322a10dcfe648445e6cd0001f4f8c548cc3398884ff77373f4e975d1e601fd5bae",
//   //   amountIn: swapAmount,
//   //   amountOutMinimum: 0,
//   // })
//   // console.log("swap  tx  ", tx);

// });

// task("rswapuni", "Prints swap", async (taskArgs, bre) => {
//   const swapAmount = 10;//bre.ethers.utils.parseUnits("0.0001","mwei");
//   let tokens =  ["0xB3ACF8794D4Fb214809e322a10DcfE648445e6cD", "0xf8c548cc3398884ff77373f4e975d1e601fd5bae"]
//   let router = "0x7CA52848D74bC958C0bEc702075EcE329c186719"
//   let deadline = Math.round(new Date() / 1000)  +  600
//   const accounts = await bre.ethers.getSigners();
//   let LOW = 500
  
//   const TetherToken = await ethers.getContractFactory("TetherToken")
//   const tetherToken = TetherToken.attach(tokens[0])
//   //await tetherToken.approve(router, swapAmount)

//   const SummaSwapV3Router = await ethers.getContractFactory("SummaSwapV3Router")
//   const summaSwapV3Router = SummaSwapV3Router.attach(router)

//     let address = await accounts[0].getAddress();

//   console.log(deadline);
//   console.log(address);

//   const tx =  await summaSwapV3Router.exactInput({
//     recipient: address,
//     deadline: deadline,
//     //path: encodePath([tokens[0], tokens[1]], [LOW]),
//     path: "0xf8c548cc3398884ff77373f4e975d1e601fd5bae002710b3acf8794d4fb214809e322a10dcfe648445e6cd",
//     amountIn: swapAmount,
//     amountOutMinimum: 0,
//   })
//   console.log("swap  tx  ", tx);

// });

// task("swapusdt", "Prints swap", async (taskArgs, bre) => {
//   const swapAmount = 10000000;//bre.ethers.utils.parseUnits("0.0001","mwei");
//   let tokens =  ["0xcb6b2584113dd17e4b60b40ab4ecf929c4620f08", "0x917df3087f7f22bb9a9db475323de267799d2c78"]
//   let router = "0xE592427A0AEce92De3Edee1F18E0157C05861564"
//   let deadline = Math.round(new Date() / 1000)  +  600
//   const accounts = await bre.ethers.getSigners();
//   let LOW = 500
  
//   const TetherToken = await ethers.getContractFactory("TetherToken")
//   const tetherToken = TetherToken.attach(tokens[0])
//   //await tetherToken.approve(router, swapAmount)
  
//   const SummaSwapV3Router = await ethers.getContractFactory("SummaSwapV3Router")
//   const summaSwapV3Router = SummaSwapV3Router.attach(router)

//     let address = await accounts[0].getAddress();

//   console.log(deadline);
//   console.log(address);

//   const tx =  await summaSwapV3Router.exactInput({
//     recipient: address,
//     deadline: deadline,
//     //path: encodePath([tokens[0], tokens[1]], [LOW]),
//     path: "0xcb6b2584113dd17e4b60b40ab4ecf929c4620f080001f4917df3087f7f22bb9a9db475323de267799d2c78",
//     amountIn: swapAmount,
//     amountOutMinimum: 0,
//   })
//   console.log("swap  tx  ", tx);
// });


// task("swapuni", "Prints swap", async (taskArgs, bre) => {
//   const swapAmount = 10000000;//bre.ethers.utils.parseUnits("0.0001","mwei");
//   let tokens =  ["0xcb6b2584113dd17e4b60b40ab4ecf929c4620f08", "0x917df3087f7f22bb9a9db475323de267799d2c78"]
//   let router = "0xE592427A0AEce92De3Edee1F18E0157C05861564"
//   let deadline = Math.round(new Date() / 1000)  +  600
//   const accounts = await bre.ethers.getSigners();
//   let LOW = 500
  
//   const TetherToken = await ethers.getContractFactory("TetherToken")
//   const tetherToken = TetherToken.attach(tokens[0])
//   //await tetherToken.approve(router, swapAmount)
  
//   const SummaSwapV3Router = await ethers.getContractFactory("SummaSwapV3Router")
//   const summaSwapV3Router = SummaSwapV3Router.attach(router)

//     let address = await accounts[0].getAddress();

//   console.log(deadline);
//   console.log(address);

//   const tx =  await summaSwapV3Router.exactInput({
//     recipient: address,
//     deadline: deadline,
//     //path: encodePath([tokens[0], tokens[1]], [LOW]),
//     path: "0x917df3087f7f22bb9a9db475323de267799d2c780001f4cb6b2584113dd17e4b60b40ab4ecf929c4620f08",
//     amountIn: swapAmount,
//     amountOutMinimum: 0,
//   })
//   console.log("swap  tx  ", tx);

// });

task("quoteExactInput", "Prints quoteExactInput", async (taskArgs, bre) => {
  const swapAmount = 100;//bre.ethers.utils.parseUnits("0.0001","mwei");
  let tokens =  ["0xe1F20070227eaCFC2C60d9f50aD0d99694550F6C", "0xF8c548cC3398884FF77373F4e975D1E601Fd5bAE"]
  let quote = "0x96dd85E5880f7c9884CB2fD2F826Fa9706758900"
  const accounts = await bre.ethers.getSigners();
  let LOW = 500
  
  const Quoter = await ethers.getContractFactory("Quoter")
  const quoter = Quoter.attach(quote)
  //console.log(quoter);

  
  let address = await accounts[0].getAddress();
  const quoteTx = await quoter.quoteExactInput(
    "0x0b40a188D28F8cF561Ad7B665dfb0f3D3b77BffF",
    //encodePath([tokens[0], tokens[1]], [LOW]),
    "0xe1f20070227eacfc2c60d9f50ad0d99694550f6c0001f4f8c548cc3398884ff77373f4e975d1e601fd5bae",
    100
  )
    
  // console.log("quoteExactInput  ", quoteTx);
  

});