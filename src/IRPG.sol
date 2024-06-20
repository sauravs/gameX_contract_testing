// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRPGItemNFT {
    struct StatType { // No change to this stat.
        uint8 stat1;
        uint8 stat2;
        uint8 specialType;
        uint8 specialPoints;
    }
    function getOwner(uint256 tokenId) external view returns (address);

    function lockStatus(uint256 tokenId) external view returns (bool);

    function setTokenLockStatus(uint256 tokenId, uint256 unlockTime) external;

    function getTokenStats(uint256 tokenId)
        external
        view
        returns (
            uint8,
            uint8,
            uint8,
            uint8
        );

    // function updateStatsAndUser(                               //@audit this function not found in RPG.sol // but available in ccip.sol
    //     uint256 tokenId,
    //     address newOwner,
    //     uint8 stat1,
    //     uint8 stat2,
    //     uint8 specialType,
    //     uint8 specialPoints
    // ) external;


    function mint() external payable;

    function isApprovedForAll(address owner, address operator)    // @audit available in ccip.sol
        external
        view
        returns (bool);


    // function transfer(address to, uint256 tokenId) external;   

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;



      function updateStats(                                        //ccip related
        uint256 tokenId,
        address newOwner,
        uint8 stat1,
        uint8 stat2,
        uint8 specialType,
        uint8 specialPoints
    ) external returns (bool) ;
}


 