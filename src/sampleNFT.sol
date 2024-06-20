// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SAMPLENFT is ERC721, Ownable {
    uint256 private _nextTokenId;

    constructor(address initialOwner)
        ERC721("MyToken", "MTK")
        Ownable(initialOwner)
    {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://github.com/foundry-rs/foundry/issues/7312";
    }

    function safeMint(address to) public  {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }

    function safeMintRPG() public {
              uint256 tokenId = _nextTokenId++;
         _safeMint(msg.sender, tokenId);
    }


function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        return _ownerOf(tokenId);
    }
}