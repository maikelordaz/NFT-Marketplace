const hre = require("hardhat");

async function main() {
  
  await hre.run('compile');
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  
  const Mycontract = await hre.ethers.getContractFactory("Mycontract ");
  const contract = await Mycontract.deploy();
  await contract.deployed();
  console.log("Mycontract deployed to:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
