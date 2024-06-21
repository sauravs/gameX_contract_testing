// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "../RPG.sol";
import {CheatCodes} from "forge-std/CheatCodes.sol";

contract RPGTest is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    RPG private rpg;
    address private ccipRouter;

    function setUp() public {
        rpg = new RPG();
        ccipRouter = address(1); // Assuming address(1) is the CCIP Router for this example
        // Assuming the RPG contract has a function to set the CCIP Router or it's set upon deployment
        // If there's a function like `setCCIPRouter(address _ccipRouter)`, it should be called here
    }

    function testSetTokenLockStatus() public {
        uint256 tokenId = 1;
        uint256 unlockTime = block.timestamp + 1 days;

        // Simulate calling from the CCIP Router
        cheats.prank(ccipRouter);
        rpg.setTokenLockStatus(tokenId, unlockTime);

        // Verify the token lock status
        assertEq(rpg.tokenLockedTill(tokenId), unlockTime);
    }

    function testAccessWithLockedToken() public {
        uint256 tokenId = 2;
        uint256 unlockTime = block.timestamp + 1 days;

        // Lock the token by setting a future unlock time
        cheats.prank(ccipRouter);
        rpg.setTokenLockStatus(tokenId, unlockTime);

        // Attempt to access a function protected by the `isUnlocked` modifier before unlock time
        cheats.warp(block.timestamp + 12 hours); // Warp halfway to the unlock time
        cheats.expectRevert("Token is locked");
        // Call the protected function here, e.g., `rpg.useToken(tokenId);`
    }

    function testAccessWithUnlockedToken() public {
        uint256 tokenId = 3;
        uint256 unlockTime = block.timestamp - 1 days; // Set unlock time in the past

        // Unlock the token by setting a past unlock time
        cheats.prank(ccipRouter);
        rpg.setTokenLockStatus(tokenId, unlockTime);

        // Warp to a time after the unlock time just to be sure
        cheats.warp(block.timestamp + 1 days);

        // Call the protected function here, e.g., `rpg.useToken(tokenId);`
        // No revert expected if the function is correctly implemented and uses the `isUnlocked` modifier
    }
}