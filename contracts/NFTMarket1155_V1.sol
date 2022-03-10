// SPDX-License-Identifier: MIT
/**
* @title NFT Marketplace
* @author Maikel Ordaz
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
    uint private _listId;

    struct NFTitem {
        uint tokenId;
        uint tokenAmount;
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

    event NFTitemListed (
        uint indexed tokenId,
        uint tokenAmount,
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

    function initialize() public initializer {
        __ERC1155_init("");
        __Ownable_init();
        __UUPSUpgradeable_init();
        _listId = 0;
        ETHpricefeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        DAIpricefeed = AggregatorV3Interface(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9);
        LINKpricefeed = AggregatorV3Interface(0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c);
        DAItoken = IERC20Upgradeable(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        LINKtoken = IERC20Upgradeable(0x514910771AF9Ca656af840dff83E8264EcF986CA);        
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
            ( , int ETHprice, , , ) = 
            ETHpricefeed.latestRoundData();
            return uint (ETHprice / 1e8);
    }

    function getDAIprice() 
        public 
        view 
        returns (uint) {
            (, int DAIprice, , , ) = 
            DAIpricefeed.latestRoundData();
            return uint (DAIprice / 1e8);
    }

    function getLINKprice() 
        public 
        view 
        returns (uint) {
            (, int LINKprice, , , ) = 
            LINKpricefeed.latestRoundData();
            return uint (LINKprice / 1e8);
    }
    /**
    * @dev A function to list NFT items on the marketplace.
    * @param tokenId the Id of the tokens.
    * @param tokenAmount the amount of tokens to put on sale.
    * @param NFTprice the price for all the collection in USD.
    * @param tokenAddress the contract address of the token.
    */
    function listNFTitem(uint tokenId, uint tokenAmount, uint NFTprice, address tokenAddress)
        public {

            require (NFTprice > 0, "Price can not be 0.");
            require (tokenAmount > 0, "You have to sale at least one token.");
           setApprovalForAll(owner(), true);
           _listId++;
            _idToNFTitem[_listId] = NFTitem (
                tokenId,
                tokenAmount,
                NFTprice,                
                tokenAddress,
                payable(msg.sender),
                msg.sender,
                false,
                false
            );                                 
            emit NFTitemListed (
                tokenId,
                tokenAmount,
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
    * price amount, etc.
    */
    function buyNFTitemETH(uint listId)
        public
        payable {

            uint ETHprice = getETHprice();
            uint NFTprice = _idToNFTitem[listId].NFTprice / ETHprice;
            uint fee = NFTprice * 1 / 100; 
            address seller = _idToNFTitem[listId].seller;
            uint tokenAmount = _idToNFTitem[listId].tokenAmount;
            uint actualAmount = balanceOf(seller, listId);
            require(tokenAmount >= actualAmount, "The seller no longer owns this item.");
            require(_idToNFTitem[listId].cancelled == false, "This item is no longer on sale.");
            require (msg.value >= NFTprice, "Pay the complete price.");                    
            safeTransferFrom(seller, msg.sender, listId, tokenAmount, "");
            _idToNFTitem[listId].NFTowner = payable(msg.sender);
            _idToNFTitem[listId].sold = true;
            payable(seller).transfer(NFTprice);
            _idToNFTitem[listId].seller = payable(address(0)); 
            payable(address(this)).transfer(fee);            
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
            uint tokenAmount = _idToNFTitem[listId].tokenAmount;
            uint actualAmount = balanceOf(seller, listId);
            require(tokenAmount == actualAmount, "The seller no longer owns this item.");
            require(_idToNFTitem[listId].cancelled == false, "This item is no longer on sale.");
            require (msg.value == NFTprice, "Pay the complete price.");                    
            DAItoken.transferFrom(msg.sender, seller, msg.value);
            safeTransferFrom(seller, msg.sender, listId, tokenAmount, "");
            _idToNFTitem[listId].NFTowner = payable(msg.sender);
            _idToNFTitem[listId].sold = true;
            _idToNFTitem[listId].seller = payable(address(0)); 
            payable(address(this)).transfer(fee);
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
            uint tokenAmount = _idToNFTitem[listId].tokenAmount;
            uint actualAmount = balanceOf(seller, listId);
            require(tokenAmount == actualAmount, "The seller no longer owns this item.");
            require(_idToNFTitem[listId].cancelled == false, "This item is no longer on sale.");
            require (msg.value == NFTprice, "Pay the complete price.");                    
            LINKtoken.transferFrom(msg.sender, seller, msg.value);
            safeTransferFrom(seller, msg.sender, listId, tokenAmount, "");
            _idToNFTitem[listId].NFTowner = payable(msg.sender);
            _idToNFTitem[listId].sold = true;
            _idToNFTitem[listId].seller = payable(address(0)); 
            payable(address(this)).transfer(fee);
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
    *@dev a function to withdraw the payments for the mint.
    */
    function withdraw() 
        public 
        payable 
        onlyOwner {        
            payable(msg.sender).transfer(address(this).balance);        
    } 
    /** @dev the function to authorize new versions of the marketplace.
    * @param newImplementation is the address of the new implementation contract
    */
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner  
        override {}
}