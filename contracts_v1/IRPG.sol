// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRPGItemNFT {
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

    function updateStatsAndUser(                               //@audit this function not found in RPG.sol // but available in ccip.sol
        uint256 tokenId,
        address newOwner,
        uint8 stat1,
        uint8 stat2,
        uint8 specialType,
        uint8 specialPoints
    ) external;

    function addTokenStats(                                      //@audit this function not found in RPG.sol and also not avaialble in ccip.sol
        address recipient,
        uint256 tokenId,
        uint8 stat1,
        uint8 stat2,
        uint8 specialType,
        uint8 specialPoints
    ) external;

    function mint() external payable;

    function powerLevel(uint256 tokenId) external view returns (uint256);   //@audit this function not found in RPG.sol and also not avaialble in ccip.sol

    function powerLevelColor(uint256 tokenId)
        external
        view
        returns (string memory);

    function calculatePrice(
        uint8 stat1,
        uint8 stat2,
        uint8 specialType,
        uint8 specialPoints
    ) external pure returns (uint256);

    function upgrade(uint256 tokenId) external payable;

    function getStat(string calldata statLabel, uint256 tokenId)
        external
        view
        returns (uint8);

    function getSpecial(uint256 tokenId) external view returns (uint8, uint8);

    function isApprovedForAll(address owner, address operator)    // @audit available in ccip.sol
        external
        view
        returns (bool);

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address);   // @audit not available in RPG.sol and also not in ccip.sol

    function transfer(address to, uint256 tokenId) external;   

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


 
