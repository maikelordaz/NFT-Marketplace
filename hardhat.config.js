require ("dotenv").config();
require ("@nomiclabs/hardhat-waffle");
require ("@nomiclabs/hardhat-etherscan");
require ("hardhat-gas-reporter");
require ("solidity-coverage");
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
   solidity: "0.8.4",

  networks: {
    rinkeby: {
      url: process.env.NETWORK_RINKEBY_URL || '',
      accounts: process.env.NETWORK_RINKEBY_PRIVATE_KEY !== undefined 
      ? [process.env.NETWORK_RINKEBY_PRIVATE_KEY] : [],
    },  
  },

  etherscan: {
    apiKey: {
      rinkeby: process.env.ETHERSCAN_API_KEY
    }
  }

};
