const { expect } = require("chai");
const { ethers } = require("hardhat");
const { Contract } = require("ethers");

//START OF TEST
describe("Mycontract", function () {

    let Mycontract;
    let contract;
    let address1;
    let address2;
    let address3;
   
//BEFORE EACH TEST THE CONTRACT IS DEPLOYED
    beforeEach(async function () {
    
        TheLittleTraveler = await ethers.getContractFactory("Mycontract");
        [address1, address2, address3] = await ethers.getSigners();      

});
