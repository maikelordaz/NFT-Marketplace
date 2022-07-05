const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { Contract, BigNumber } = require("ethers");


//START OF TEST
describe("NFTMarket1155", function () {

    let NFTMarket1155;
    let market;
    let MyTestToken;
    let tokenContract;
    let tokenId1 = 1;
    let tokenId2 = 3;
    let tokenAmount = 10;
    let price = 10;
    let owner;
    let Alice;
    let Bob;
    let Charlie;
    let Daniel;
   
//BEFORE EACH TEST THE CONTRACT IS DEPLOYED
    beforeEach(async function () {    
        NFTMarket1155 = await ethers.getContractFactory("NFTMarket1155");
        MyTestToken = await ethers.getContractFactory("MyTestToken");
        [owner, Alice, Bob, Charlie, Daniel] = await ethers.getSigners();
    });
//TESTS
    it("Should deploy the marketplace contract, UUPS upgradeable", async function () {
        market = await upgrades.deployProxy(NFTMarket1155, { kind: 'uups' });
        await market.deployed();         
    });

    // with this test the test token contract is tested  
   it("Should deploy the NFT test contract and mint two NFT tokens", async function () {
        tokenContract = await MyTestToken.deploy(market.address);
        await tokenContract.deployed();   
        const NFTAddress = tokenContract.address; 
        await tokenContract.connect(Alice).createToken(tokenAmount);
        await expect(tokenContract.connect(Alice).createToken(tokenAmount)).
            to.emit(tokenContract, "NewTokenCreated").
            withArgs(Alice.address, tokenId1, tokenAmount); 
        await tokenContract.connect(Bob).createToken(tokenAmount);
        await expect(tokenContract.connect(Bob).createToken(tokenAmount)).
            to.emit(tokenContract, "NewTokenCreated").
            withArgs(Bob.address, tokenId2, tokenAmount);                   
    });

    //Start of the marketplace test

    it("Should set the right owner of the marketplace", async function (){
        expect(await market.owner()).to.equal(owner.address);
    });

    //One test to check the three functions related to the prices
    it("Should be able to successfully get the price of ETH, DAI and LINK", async function () {
        expect(await market.getETHprice()).not.be.null;
        expect(await market.getDAIprice()).not.be.null;
        expect(await market.getLINKprice()).not.be.null;
    })

    //Three tests to check the listNFTitem function

    it("Should fail to list an item if the seller give the price as 0", async function (){        
        await expect(market.connect(Charlie).listNFTitem(5, 10, 0, tokenContract.address)).
            to.be.revertedWith("Price can not be 0.");
    });

    it("Should fail to list an item if the seller does not sell anything", async function (){        
        await expect(market.connect(Charlie).listNFTitem(5, 0, 100, tokenContract.address)).
            to.be.revertedWith("You have to sale at least one token.");
    });

    it("Should list two items, minted from the NFTtestToken contract, in the marketplace",
      async function (){
        //First item from Alice
        await market.connect(Alice).listNFTitem(
            tokenId1, tokenAmount, price, tokenContract.address);
        await expect(market.connect(Alice).setApprovalForAll(owner.address, true));
        await expect(market.connect(Alice).listNFTitem(
            tokenId1, tokenAmount, price, tokenContract.address)).
            to.emit(market, "NFTitemListed").withArgs(
            tokenId1, tokenAmount, price, tokenContract.address, 
            Alice.address, Alice.address, false, false);
        //Second item from Bob
        await market.connect(Bob).listNFTitem(
            tokenId2, tokenAmount, price, tokenContract.address);
        await expect(market.connect(Bob).setApprovalForAll(owner.address, true));
        await expect(market.connect(Bob).listNFTitem(
            tokenId2, tokenAmount, price, tokenContract.address)).
            to.emit(market, "NFTitemListed").withArgs(
            tokenId2, tokenAmount, price, tokenContract.address, 
            Bob.address, Bob.address, false, false);
    });
    
    it("Should return a listed item", async function (){
        await market.getNFTitem(0);
    });

    //Three tests to check the cancelSale function

    it("Should fail to cancel a sale if the seller is not the owner of the token", async function (){        
        await expect(market.connect(Charlie).cancelSale(tokenId2)).
            to.be.revertedWith("Only the seller can cancel this sale.");
    });
    
    it("Should cancel a sale", async function (){
        await expect(market.connect(Bob).cancelSale(tokenId2)).
           to.emit(market, "Cancel").withArgs(tokenId2, Bob.address);
    });

    it("Should fail to cancel a sale if the item is already cancelled", async function (){        
        await expect(market.connect(Bob).cancelSale(tokenId2)).
            to.be.revertedWith("This item is no longer on sale.");
    });

    it("Should purchase a sale with ETH", async function (){
        await market.buyNFTitemETH(tokenId1, {value: ethers.utils.parseEther("10")});
    });

})