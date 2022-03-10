require ("dotenv").config();
require ("@nomiclabs/hardhat-waffle");
require ("@nomiclabs/hardhat-etherscan");
require ("hardhat-gas-reporter");
require ("solidity-coverage");
require("@openzeppelin/hardhat-upgrades");
require('@openzeppelin/test-helpers/configure');
require("@nomiclabs/hardhat-web3");

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
   solidity: "0.8.4",

   defaultNetwork: "hardhat",
   networks: {
     hardhat: {
       forking: {
         url: process.env.ALCHEMY_MAINNET_RPC_URL,
         blockNumber: 14300000
       }
     }
    }
};
