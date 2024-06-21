// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "../RPG.sol"; // Adjust the import path to your RPG contract location
import {CheatCodes} from "forge-std/CheatCodes.sol";

contract RPGTest is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    RPG private rpg;
    address private ccipRouter = address(0x1); // Mock CCIP router address

    function setUp() public {
        cheats.prank(ccipRouter);
        rpg = new RPG();
        cheats.startPrank(ccipRouter);
        rpg.setCCIPHandler(ccipRouter); // Assuming there's a function to set the CCIP handler
        cheats.stopPrank();
    }

    function testUpdateStatsSuccess() public {
        uint256 tokenId = 1;
        address newOwner = address(this);
        uint8 stat1 = 5;
        uint8 stat2 = 10;
        uint8 specialType = 15;
        uint8 specialPoints = 20;

        cheats.prank(ccipRouter);
        bool success = rpg.updateStats(tokenId, newOwner, stat1, stat2, specialType, specialPoints);
        assertTrue(success, "UpdateStats should succeed");

        // Verify the stats were updated
        (uint8 updatedStat1, uint8 updatedStat2, uint8 updatedSpecialType, uint8 updatedSpecialPoints) = rpg.upgradeMapping(tokenId);
        assertEq(updatedStat1, stat1, "Stat1 was not updated correctly");
        assertEq(updatedStat2, stat2, "Stat2 was not updated correctly");
        assertEq(updatedSpecialType, specialType, "SpecialType was not updated correctly");
        assertEq(updatedSpecialPoints, specialPoints, "SpecialPoints was not updated correctly");
    }

    function testUpdateStatsRevertsForNonCCIPRouter() public {
        uint256 tokenId = 2;
        address newOwner = address(this);
        uint8 stat1 = 5;
        uint8 stat2 = 10;
        uint8 specialType = 15;
        uint8 specialPoints = 20;

        cheats.expectRevert("Caller is not the CCIP router");
        rpg.updateStats(tokenId, newOwner, stat1, stat2, specialType, specialPoints);
    }
}