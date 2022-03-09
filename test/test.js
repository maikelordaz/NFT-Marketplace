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
    let price = 100;
    let owner;
    let NFTseller1;
    let NFTseller2;
    let NFTseller3;
    let NFTbuyer;
   
//BEFORE EACH TEST THE CONTRACT IS DEPLOYED
    beforeEach(async function () {    
        NFTMarket1155 = await ethers.getContractFactory("NFTMarket1155");
        MyTestToken = await ethers.getContractFactory("MyTestToken");
        [owner, NFTseller1, NFTseller2, NFTseller3, NFTbuyer] = await ethers.getSigners();
    });
//TESTS
    it("Should deploy the marketplace contract, UUPS upgradeable", async function () {
        market = await upgrades.deployProxy(NFTMarket1155, { kind: 'uups' });
        await market.deployed();         
    });
   it("Should deploy the NFT test contract", async function () {
        tokenContract = await MyTestToken.deploy(market.address);
        await tokenContract.deployed();   
        const NFTAddress = tokenContract.address;                    
    });
    it("Should mint a new NFT Token on the NFTtestToken contract", async function (){
        await tokenContract.connect(NFTseller1).createToken(tokenAmount);
        await expect(tokenContract.connect(NFTseller1).createToken(tokenAmount)).
            to.emit(tokenContract, "NewTokenCreated").
            withArgs(NFTseller1.address, tokenId1, tokenAmount);   
    });
    it("Should mint a second NFT Token on the NFTtestToken contract", async function (){
        await tokenContract.connect(NFTseller2).createToken(tokenAmount);
        await expect(tokenContract.connect(NFTseller2).createToken(tokenAmount)).
            to.emit(tokenContract, "NewTokenCreated").
            withArgs(NFTseller2.address, tokenId2, tokenAmount);     
    });
    it("Should set the right owner of the marketplace", async function (){
        expect(await market.owner()).to.equal(owner.address);
    });
    it("Should list an item in the marketplace", async function (){
        await market.connect(NFTseller1).listNFTitem(
            tokenId1, tokenAmount, price, tokenContract.address);
        await expect(market.connect(NFTseller1).listNFTitem(
            tokenId1, tokenAmount, price, tokenContract.address)).
            to.emit(market, "NFTitemListed").withArgs(
            tokenId1, tokenAmount, price, tokenContract.address, 
            NFTseller1.address, NFTseller1.address, false, false);
    });
    it("Should list a second item in the marketplace", async function (){
        await market.connect(NFTseller2).listNFTitem(
            tokenId2, tokenAmount, price, tokenContract.address);
        await expect(market.connect(NFTseller2).listNFTitem(
            tokenId2, tokenAmount, price, tokenContract.address)).
            to.emit(market, "NFTitemListed").withArgs(
            tokenId2, tokenAmount, price, tokenContract.address, 
            NFTseller2.address, NFTseller2.address, false, false);
    });
    it("Should fail to list an item if the seller give the price as 0", async function (){        
        await expect(market.connect(NFTseller3).listNFTitem(5, 10, 0, tokenContract.address)).
            to.be.revertedWith("Price can not be 0.");
    });
    it("Should fail to list an item if the seller give the token amount as 0", async function (){        
        await expect(market.connect(NFTseller3).listNFTitem(5, 0, 100, tokenContract.address)).
            to.be.revertedWith("You have to sale at least one token.");
    });
    it("Should return a listed item", async function (){
        await market.getNFTitem(0);
    });
    it("Should cancel a sale", async function (){
        await expect(market.connect(NFTseller2).cancelSale(tokenId2)).
           to.emit(market, "Cancel").withArgs(
           tokenId2, NFTseller2.address);
    });
    it("Should fail to cancel a sale if the seller is not the owner of the token", async function (){        
        await expect(market.connect(NFTseller3).cancelSale(tokenId2)).
            to.be.revertedWith("Only the seller can cancel this sale.");
    });
    it("Should fail to cancel a sale if the item is already cancelled", async function (){        
        await expect(market.connect(NFTseller2).cancelSale(tokenId2)).
            to.be.revertedWith("This item is no longer on sale.");
    });

    it("Should purchase a market sale", async function (){        
        await market.connect(NFTbuyer).buyNFTitemETH(tokenId2, {value: ethers.utils.parseEther("100")});
    });




})
