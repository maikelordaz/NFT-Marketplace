require ("dotenv").config();
require ("@nomiclabs/hardhat-waffle");
require ("@nomiclabs/hardhat-etherscan");
require ("hardhat-gas-reporter");
require ("solidity-coverage");
require("@openzeppelin/hardhat-upgrades");
require('@openzeppelin/test-helpers/configure');

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
/*
  networks: {
    defaultNetwork: "hardhat",
    
    hardhat: {
      chainId: 1337
    },

    rinkeby: {
      url: process.env.NETWORK_RINKEBY_URL || '',
      accounts: process.env.NETWORK_RINKEBY_PRIVATE_KEY !== undefined 
      ? [process.env.NETWORK_RINKEBY_PRIVATE_KEY] : [],
    },  
    
  },
  */

  etherscan: {
    apiKey: {
      rinkeby: process.env.ETHERSCAN_API_KEY
    }
  }

};
