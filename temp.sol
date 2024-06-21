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
        // Mint a token for testing; assuming mint function exists and is accessible for testing
        // rpg.mint(address(this), 1); // Uncomment if minting is needed
    }

    function testGetStatForMintedAndUnlockedToken() public {
        uint256 tokenId = 1;
        // Assuming a function to set upgrade stats exists
        // rpg.setUpgradeStats(tokenId, 5, 5, 0, 0); // Example upgrade stats; adjust based on actual contract

        // Test retrieval of stat1
        uint8 stat1 = rpg.getStat("l1", tokenId);
        assertEq(stat1, 15, "Incorrect stat1 value"); // 10 (base) + 5 (upgrade)

        // Test retrieval of stat2
        uint8 stat2 = rpg.getStat("l2", tokenId);
        assertEq(stat2, 25, "Incorrect stat2 value"); // 20 (base) + 5 (upgrade)
    }

    function testGetStatForLockedToken() public {
        uint256 tokenId = 2;
        // Lock the token; assuming a function exists to lock the token
        // rpg.lockToken(tokenId, futureTimestamp); // Lock the token; adjust based on actual contract

        cheats.expectRevert("Token is locked");
        rpg.getStat("l1", tokenId);
    }

    function testGetStatForUnmintedToken() public {
        uint256 tokenId = 999; // Assuming this token is not minted

        cheats.expectRevert("Token is not Minted");
        rpg.getStat("l1", tokenId);
    }

    function testGetStatWithInvalidStatLabel() public {
        uint256 tokenId = 1;
        uint8 stat = rpg.getStat("invalidLabel", tokenId);
        assertEq(stat, 0, "Invalid stat label should return 0");
    }
}