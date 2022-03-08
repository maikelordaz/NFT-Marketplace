const { expect } = require("chai");
const { ethers } = require("hardhat");
const { Contract, BigNumber } = require("ethers");

//START OF TEST
describe("NFTMarket1155", function () {

    let NFTMarket1155;
    let market;
    let address1;
    let address2;
    let address3;
   
//BEFORE EACH TEST THE CONTRACT IS DEPLOYED
    beforeEach(async function () {
    
        NFTMarket1155 = await ethers.getContractFactory("NFTMarket1155");
        [address1, address2, address3] = await ethers.getSigners();      

    });

//TESTS

    it("Should deploy the contract", async function () {
        //market = await NFTMarket1155.deploy();
        market = await upgrades.deployProxy(NFTMarket1155, { kind: 'uups' });
        //box = await upgrades.deployProxy(Box, { kind: 'uups' })
        await market.deployed();            
   });

})
