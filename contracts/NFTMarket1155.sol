// SPDX-License-Identifier: MIT
/**
* @title 
* @author Maikel Ordaz
* @notice 
*/

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTMarket1155 is ERC1155{
    
    using Counters for Counters.Counter;


//VARIABLES

    Counters.Counter private _tokenIDs;
    Counters.Counter private _NFTSold;
    uint listingPrice = 0.01 ether;
    address payable owner;

    struct NFTitem {
        uint tokenId;
        uint tokenAmmount;
        uint price;
        address tokenAddress;
        address payable seller;
        address NFTowner;      
        bool sold;
        bool cancelled;
    }

//MAPPINGS

    mapping(uint => NFTitem) private idToNFTitem;

//EVENTS

    event NFTitemCreated (
        uint indexed tokenId,
        uint tokenAmmount,
        uint price,
        address tokenAddress,
        address seller,
        address NFTowner,        
        bool sold,
        bool cancelled
    );

    event Sale (
        uint tokenId,
        uint price,
        address buyer
    );

    event Cancel (
        uint tokenId,
        address seller
    );


//FUNCTIONS

    constructor(){

            owner = payable(msg.sender);

    }
   
    function updateListingPrice(uint _listingPrice) 
        public 
        payable {

            require(owner == msg.sender, "only the owner can call this function");
            listingPrice = _listingPrice;

        }

   
    function getListingPrice() 
        public
        view
        returns(uint) {

            return listingPrice;

        }


    function listNFTitem(uint tokenId, uint price, uint tokenAmmount, address tokenAddress)
        public
        payable {

            require (price > 0, "price can not be 0");
            require (msg.value == listingPrice, "pay the listing fee");
            require (tokenAmmount > 0, "You have to sale at least one token");
            idToNFTitem[tokenId] = NFTitem (
                tokenId,
                price,
                tokenAmmount,
                tokenAddress,
                payable(msg.sender),
                msg.sender,
                false,
                false
            );
            isApprovedForAll(msg.sender, address(this));          
            emit NFTitemCreated (
                tokenId,
                price,
                tokenAmmount,
                tokenAddress,
                msg.sender,
                msg.sender,
                false,
                false
            );            
        }

    function buyNFTitem(uint tokenId)
        public
        payable {

            uint price = idToNFTitem[tokenId].price;
            address seller = idToNFTitem[tokenId].seller;
            uint tokenAmmount = idToNFTitem[tokenId].tokenAmmount;
            require(idToNFTitem[tokenId].cancelled == false, "This item is no longer on sale.");
            require (msg.value == price, "pay the complete price");            
            safeTransferFrom(address(this), msg.sender, tokenId, tokenAmmount, "");
            idToNFTitem[tokenId].NFTowner = payable(msg.sender);
            idToNFTitem[tokenId].sold = true;
            idToNFTitem[tokenId].seller = payable(address(0));
            _NFTSold.increment(); 
            payable(owner).transfer(listingPrice);
            payable(seller).transfer(msg.value);
            emit Sale (
                tokenId,
                price,
                msg.sender);
        }

    function cancelSale(uint tokenId)
        public {
            require (msg.sender == idToNFTitem[tokenId].seller, 
                    "Only the seller can cancel this sale.");
            require (idToNFTitem[tokenId].cancelled == false, "This item is no longer on sale.");
            require (idToNFTitem[tokenId].sold == false, "This item is already sold.");            
            idToNFTitem[tokenId].cancelled = true;           
            emit Cancel (
                tokenId,
                msg.sender);

        }

        function _beforeTokenTransfer(
            address operator,
            address from,
            address to,
            uint256[] memory ids,
            uint256[] memory amounts,
            bytes memory data) 
            internal       
            override {
                require(from != to);
                super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        }

}