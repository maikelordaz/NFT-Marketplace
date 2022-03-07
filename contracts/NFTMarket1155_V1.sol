// SPDX-License-Identifier: MIT
/**
* @title 
* @author Maikel Ordaz
* @notice 
*/

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract NFTMarket1155 is 
                        Initializable, 
                        ERC1155Upgradeable, 
                        OwnableUpgradeable,
                        UUPSUpgradeable {  

//VARIABLES

    uint private _listId = 0;
    uint listingPrice = 0.01 ether;

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

    mapping(uint => NFTitem) private _idToNFTitem;

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

    constructor() initializer {}

    function initialize() public initializer {
        __ERC1155_init("");
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function updateListingPrice(uint _listingPrice) 
        public 
        payable 
        onlyOwner {            
            listingPrice = _listingPrice;
    }
   
    function getListingPrice() 
        public
        view
        returns(uint) {
            return listingPrice;
    }

    function listNFTitem(uint tokenId, uint tokenAmmount, uint price, address tokenAddress)
        public
        payable {

            require (price > 0, "price can not be 0");
            require (msg.value == listingPrice, "pay the listing fee");
            require (tokenAmmount > 0, "You have to sale at least one token");
            isApprovedForAll(msg.sender, owner()); 
            _idToNFTitem[_listId] = NFTitem (
                tokenId,
                tokenAmmount,
                price,                
                tokenAddress,
                payable(msg.sender),
                msg.sender,
                false,
                false
            );
            _listId++;                     
            emit NFTitemCreated (
                tokenId,
                tokenAmmount,
                price,                
                tokenAddress,
                msg.sender,
                msg.sender,
                false,
                false
            );            
    }

    function getNFTitem(uint listId) 
        public
        view
        returns(NFTitem memory) {
            return _idToNFTitem[listId];
    }

    function buyNFTitem(uint listId)
        public
        payable {

            uint price = _idToNFTitem[listId].price;
            address seller = _idToNFTitem[listId].seller;
            uint tokenAmmount = _idToNFTitem[listId].tokenAmmount;
            require(_idToNFTitem[listId].cancelled == false, "This item is no longer on sale.");
            require (msg.value == price, "pay the complete price");
            if (msg.value > price) {
                uint excedent = msg.value - price;
                payable(msg.sender).transfer(excedent);                
                safeTransferFrom(seller, msg.sender, listId, tokenAmmount, "");
                _idToNFTitem[listId].NFTowner = payable(msg.sender);
                _idToNFTitem[listId].sold = true;
                _idToNFTitem[listId].seller = payable(address(0)); 
                payable(owner()).transfer(listingPrice);
                payable(seller).transfer(price);
                emit Sale (
                    listId,
                    price,
                    msg.sender);
            }   else {          
                    safeTransferFrom(seller, msg.sender, listId, tokenAmmount, "");
                    _idToNFTitem[listId].NFTowner = payable(msg.sender);
                    _idToNFTitem[listId].sold = true;
                    _idToNFTitem[listId].seller = payable(address(0)); 
                    payable(owner()).transfer(listingPrice);
                    payable(seller).transfer(msg.value);
                    emit Sale (
                        listId,
                        price,
                        msg.sender);
                }
    }

    function cancelSale(uint listId)
        public {
            require (msg.sender == _idToNFTitem[listId].seller, 
                    "Only the seller can cancel this sale.");
            require (_idToNFTitem[listId].cancelled == false, "This item is no longer on sale.");
            require (_idToNFTitem[listId].sold == false, "This item is already sold.");            
            _idToNFTitem[listId].cancelled = true;           
            emit Cancel (
                listId,
                msg.sender);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override {}
}