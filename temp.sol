// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "../RPGItemNFT.sol";
import {CheatCodes} from "forge-std/CheatCodes.sol";

contract RPGItemNFTTest is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    RPGItemNFT private rpgItemNFT;
    address private owner;
    address private nonOwner;

    function setUp() public {
        owner = address(1);
        nonOwner = address(2);
        cheats.prank(owner);
        rpgItemNFT = new RPGItemNFT();
    }

    function testChangeCCIP() public {
        address newCCIPHandler = address(3);

        // Test as owner
        cheats.prank(owner);
        rpgItemNFT.changeCCIP(newCCIPHandler);
        assertEq(rpgItemNFT._ccipHandler(), newCCIPHandler);

        // Test as non-owner, should revert
        cheats.prank(nonOwner);
        cheats.expectRevert("Ownable: caller is not the owner");
        rpgItemNFT.changeCCIP(newCCIPHandler);
    }

    function testSetMintPrice() public {
        uint256 newMintPrice = 20000000000000000; // 0.02 ether

        // Test as owner
        cheats.prank(owner);
        rpgItemNFT.setMintPrice(newMintPrice);
        assertEq(rpgItemNFT.mintPrice(), newMintPrice);

        // Test setting to an invalid price, should revert
        cheats.prank(owner);
        cheats.expectRevert(bytes("invalid price"));
        rpgItemNFT.setMintPrice(type(uint256).max);

        // Test as non-owner, should revert
        cheats.prank(nonOwner);
        cheats.expectRevert("Ownable: caller is not the owner");
        rpgItemNFT.setMintPrice(newMintPrice);
    }
}

function testSetMintPrice() public {
    uint256 newMintPrice = 2 ether;

    // Ensure contractOwner is the owner
    // If there's a need to set or confirm ownership, do it here

    vm.prank(contractOwner); // Prank as the owner
    rpg.setMintPrice(newMintPrice); // Attempt to set the new mint price
    assertEq(rpg.mintPrice(), newMintPrice); // Assert the mint price was successfully updated
}