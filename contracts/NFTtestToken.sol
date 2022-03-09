// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MyTestToken is ERC1155 {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenId;
    address contractAddress;
    struct NewToken {
        address ownerAddress; 
        uint tokenId; 
        uint amount;
    }

    event NewTokenCreated (
        address indexed ownerAddress,
        uint tokenId,
        uint amount
    );

    mapping(uint => NewToken) private _idToToken;

    constructor(address marketAddress) ERC1155("") {
        contractAddress = marketAddress;
    }

    function createToken(uint amount) public returns (uint) {
        uint newItemId=_tokenId.current();
        _tokenId.increment();
        _mint(msg.sender, newItemId, amount, "");
        setApprovalForAll(contractAddress, true);
        _idToToken[newItemId] = NewToken (
            msg.sender,
            newItemId,
            amount
        );
        emit NewTokenCreated(msg.sender, newItemId, amount);
        return (newItemId);   
    }

}