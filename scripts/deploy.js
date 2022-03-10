const hre = require("hardhat");

async function main() {
  
  await hre.run('compile');
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  
  const NFTMarket1155 = await hre.ethers.getContractFactory("NFTMarket1155");
  const market = await upgrades.deployProxy(NFTMarket1155, { kind: 'uups' });
  await market.deployed();
  console.log("NFTMarket1155 deployed to:", market.address);

  const MyTestToken = await hre.ethers.getContractFactory("MyTestToken");
  const tokenContract = await MyTestToken.deploy(market.address);
  await tokenContract.deployed();
  console.log("MyTestToken deployed to:", market.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
