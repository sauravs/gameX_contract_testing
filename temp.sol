// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "../RPG.sol"; // Adjust the import path to your RPG contract location
import {CheatCodes} from "forge-std/CheatCodes.sol";

contract RPGTest is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    RPG private rpg;

    function setUp() public {
        rpg = new RPG();
        // Mint a token to ensure it has an owner
        uint256 tokenId = 1;
        rpg.mint(address(this), tokenId); // Assuming the RPG contract has a mint function
        // If the contract allows setting or upgrading stats, do so here
        // e.g., rpg.setTokenStats(tokenId, 5, 5, 5, 5); // This is hypothetical and depends on your contract's functionality
    }

    function testGetTokenStatsForMintedToken() public {


         // Mint a token to ensure it has an owner
        uint256 tokenId = 1;
        rpg.mint(address(this), tokenId); // Assuming the RPG contract has a mint function


        // Expected stats based on the base stats and any upgrades applied
        // Assuming no upgrades are applied, so expected stats are just the base stats
        uint8 expectedStat1 = 10; // baseStat.stat1
        uint8 expectedStat2 = 20; // baseStat.stat2
        uint8 expectedSpecialType = 30; // baseStat.specialType
        uint8 expectedSpecialPoints = 40; // baseStat.specialPoints

        // Call getTokenStats and verify the returned values match the expected stats
        (uint8 stat1, uint8 stat2, uint8 specialType, uint8 specialPoints) = rpg.getTokenStats(tokenId);
        assertEq(stat1, expectedStat1, "Stat1 does not match expected value");
        assertEq(stat2, expectedStat2, "Stat2 does not match expected value");
        assertEq(specialType, expectedSpecialType, "SpecialType does not match expected value");
        assertEq(specialPoints, expectedSpecialPoints, "SpecialPoints does not match expected value");


          uint256 unmintedTokenId = 2; // Assuming tokenId 2 was not minted in setUp
        cheats.expectRevert("Token is not Minted");
        rpg.getTokenStats(unmintedTokenId); // This should revert as per the isTokenMinted modifier
    }

    function testGetTokenStatsRevertsForUnmintedToken() public {
        uint256 unmintedTokenId = 2; // Assuming tokenId 2 was not minted in setUp
        cheats.expectRevert("Token is not Minted");
        rpg.getTokenStats(unmintedTokenId); // This should revert as per the isTokenMinted modifier
    }
}