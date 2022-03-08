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
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract NFTMarket1155 is 
                        Initializable, 
                        ERC1155Upgradeable, 
                        OwnableUpgradeable,
                        UUPSUpgradeable {  

//VARIABLES

    IERC20Upgradeable DAItoken;
    IERC20Upgradeable LINKtoken;    
    AggregatorV3Interface internal ETHpricefeed;
    AggregatorV3Interface internal DAIpricefeed;
    AggregatorV3Interface internal LINKpricefeed;
    uint private _listId = 0;

    struct NFTitem {
        uint tokenId;
        uint tokenAmmount;
        uint NFTprice;
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
        uint NFTprice,
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
        ETHpricefeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        DAIpricefeed = AggregatorV3Interface(0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF);
        LINKpricefeed = AggregatorV3Interface(0xd8bD0a1cB028a31AA859A21A3758685a95dE4623);
        DAItoken = IERC20Upgradeable(0x95b58a6Bff3D14B7DB2f5cb5F0Ad413DC2940658);
        LINKtoken = IERC20Upgradeable(0x01BE23585060835E02B77ef475b0Cc51aA1e0709);        
    }
    /**
    * @dev The next three functions are related to the actual price of the tokens to be accepted. 
    * This tokens are ETH, DAI and LINK
    * @return uint it is typecasted tobe usefull ahead, also it is divided by the numbers of 
    * decimals
    */
    function getETHprice() 
        public 
        view 
        returns (uint) {
            (uint80 roundID, int ETHprice, uint startedAt, uint timeStamp, uint80 answeredInRound) = 
            ETHpricefeed.latestRoundData();
            return uint (ETHprice / 1e8);
    }

    function getDAIprice() 
        public 
        view 
        returns (uint) {
            (uint80 roundID, int DAIprice, uint startedAt, uint timeStamp, uint80 answeredInRound) = 
            DAIpricefeed.latestRoundData();
            return uint (DAIprice / 1e8);
    }

    function getLINKprice() 
        public 
        view 
        returns (uint) {
            (uint80 roundID, int LINKprice, uint startedAt, uint timeStamp, uint80 answeredInRound) = 
            LINKpricefeed.latestRoundData();
            return uint (LINKprice / 1e8);
    }
    /**
    * @dev A function to list NFT items on the marketplace.
    * @param tokenId the Id of the tokens.
    * @param tokenAmmount the ammount of tokens to put on sale.
    * @param NFTprice the price for all the collection in USD.
    * @param tokenAddress the contract address of the token.
    */
    function listNFTitem(uint tokenId, uint tokenAmmount, uint NFTprice, address tokenAddress)
        public {

            require (NFTprice > 0, "Price can not be 0.");
            require (tokenAmmount > 0, "You have to sale at least one token");
            isApprovedForAll(msg.sender, owner()); 
            _idToNFTitem[_listId] = NFTitem (
                tokenId,
                tokenAmmount,
                NFTprice,                
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
                NFTprice,                
                tokenAddress,
                msg.sender,
                msg.sender,
                false,
                false
            );            
    }
    /**
    * @dev a function to retrieve a market item.
    * @param listId it is the market id of the token.
    * @return NFTitem it is the object searched.
    */
    function getNFTitem(uint listId) 
        public
        view
        returns(NFTitem memory) {
            return _idToNFTitem[listId];
    }
    /**
    * @dev three functions to buy a market item, paying with each of the tokens accepted.
    * @param listId it is the market id of the item to be buyed, this id it is used to check,
    * price ammount, etc.
    */
    function buyNFTitemETH(uint listId)
        public
        payable {

            uint ETHprice = getETHprice();
            uint NFTprice = _idToNFTitem[listId].NFTprice / ETHprice;
            uint fee = NFTprice * 1 / 100; 
            address seller = _idToNFTitem[listId].seller;
            uint tokenAmmount = _idToNFTitem[listId].tokenAmmount;
            uint actualAmmount = balanceOf(seller, listId);
            require(tokenAmmount == actualAmmount, "The seller no longer owns this item.");
            require(_idToNFTitem[listId].cancelled == false, "This item is no longer on sale.");
            require (msg.value >= NFTprice, "pay the complete price");                    
            safeTransferFrom(seller, msg.sender, listId, tokenAmmount, "");
            _idToNFTitem[listId].NFTowner = payable(msg.sender);
            _idToNFTitem[listId].sold = true;
            _idToNFTitem[listId].seller = payable(address(0)); 
            payable(owner()).transfer(fee);
            payable(seller).transfer(NFTprice);
            if (msg.value > NFTprice) {
                payable(msg.sender).transfer(msg.value - NFTprice);
            }
            emit Sale (
                listId,
                NFTprice,
                msg.sender);             
    }

    function buyNFTitemDAI(uint listId)
        public
        payable {

            uint DAIprice = getDAIprice();
            uint NFTprice = _idToNFTitem[listId].NFTprice / DAIprice;
            uint fee = NFTprice * 1 / 100; 
            address seller = _idToNFTitem[listId].seller;
            uint tokenAmmount = _idToNFTitem[listId].tokenAmmount;
            uint actualAmmount = balanceOf(seller, listId);
            require(tokenAmmount == actualAmmount, "The seller no longer owns this item.");
            require(_idToNFTitem[listId].cancelled == false, "This item is no longer on sale.");
            require (msg.value == NFTprice, "pay the complete price");                    
            DAItoken.transferFrom(msg.sender, seller, msg.value);
            safeTransferFrom(seller, msg.sender, listId, tokenAmmount, "");
            _idToNFTitem[listId].NFTowner = payable(msg.sender);
            _idToNFTitem[listId].sold = true;
            _idToNFTitem[listId].seller = payable(address(0)); 
            payable(owner()).transfer(fee);
            emit Sale (
                listId,
                NFTprice,
                msg.sender);             
    }

    function buyNFTitemLINK(uint listId)
        public
        payable {

            uint LINKprice = getLINKprice();
            uint NFTprice = _idToNFTitem[listId].NFTprice / LINKprice;
            uint fee = NFTprice * 1 / 100; 
            address seller = _idToNFTitem[listId].seller;
            uint tokenAmmount = _idToNFTitem[listId].tokenAmmount;
            uint actualAmmount = balanceOf(seller, listId);
            require(tokenAmmount == actualAmmount, "The seller no longer owns this item.");
            require(_idToNFTitem[listId].cancelled == false, "This item is no longer on sale.");
            require (msg.value == NFTprice, "pay the complete price");                    
            LINKtoken.transferFrom(msg.sender, seller, msg.value);
            safeTransferFrom(seller, msg.sender, listId, tokenAmmount, "");
            _idToNFTitem[listId].NFTowner = payable(msg.sender);
            _idToNFTitem[listId].sold = true;
            _idToNFTitem[listId].seller = payable(address(0)); 
            payable(owner()).transfer(fee);
            emit Sale (
                listId,
                NFTprice,
                msg.sender);             
    }
    /**
    * @dev a function to cancel the sale.
    * @param listId it is the market id of the item.
    */
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
    /**
    * @dev the function to authorize new versions of the marketplace.
    * @param newImplementation is the address of the new implementation contract
    */
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override {}
}