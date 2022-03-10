NFT Marketplace

There are two contracts:

- NFTMarket1155_V1.sol: this is the main contract, a marketplace for ERC1155 tokens which receive a price in USD and accept payments in ETH, DAI and LINK using Chainlink oracles. Beyond that is upgradable under the UUPS pattern and only the owner can make the upgrades.

- NFTtestToken.sol: this is a secondary contract for testing purpose, it is a simple ERC1155 contract that allows to mint some tokens, the address of the contract and the tokens minted are the ones used to test the market contract.