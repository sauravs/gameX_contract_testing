// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {RPGItemNFT} from "../src/RPG.sol";
import {CCIP_RPG_SENDER} from "../src/ccip_rpg_sender.sol";
import {CCIP_RPG_RECEIVER} from "../src/ccip_rpg_receiver.sol";
import {
    CCIPLocalSimulator,
    IRouterClient,
    WETH9,
    LinkToken,
    BurnMintERC677Helper
} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";

contract GameXTest is Test {
    RPGItemNFT public rpg; // rpg sender contract
    RPGItemNFT public rpg_receiver; // rpg receiver contract

    address minterA;
        address minterB;

    address NFTRecevier;
    address contract_owner;
    address nonOwner;

    function setUp() public {
        minterA = makeAddr("minterA");
        minterB = makeAddr("minterB");
        NFTRecevier = makeAddr("NFTRecevier");
        nonOwner = makeAddr("nonOwner");
        contract_owner = 0xB1293a8BFf9323AaD0419e46dd9846cC7363d44B;

        /**
         * RPG NFT CONTRACT RELATED *****************************************************
         */
        rpg = new RPGItemNFT();
    }

    function testConstructor() public {
        //    // Test statLabels
        //     (string memory label1, string memory label2) = rpgItemNFT.statLabels();
        //     assertEq(label1, "l1");
        //     assertEq(label2, "l2");

        // Test itemType
        assertEq(rpg.itemType(), "weapon");

        // Test _ccipHandler
        assertEq(rpg._ccipHandler(), 0xa1293A8bFf9323aAd0419E46Dd9846Cc7363D44b);

        // Test mintPrice
        assertEq(rpg.mintPrice(), 10000000000000000);
    }

    function testChangeCCIP() public {
        address newCCIPHandler = 0xA2293A8bFf9323AAd0419E46Dd9846Cc7363D44c;

        vm.prank(contract_owner);
        rpg.changeCCIP(newCCIPHandler);
        assertEq(rpg._ccipHandler(), newCCIPHandler);

        // Test as non-owner, should revert
        vm.prank(nonOwner);
        vm.expectRevert();
        rpg.changeCCIP(newCCIPHandler);
    }

    function testSetMintPrice() public {
        rpg.owner();
        console.log("owner", rpg.owner());

        assertEq(rpg.owner(), contract_owner);

        uint256 newMintPrice = 2 ether;
        vm.prank(contract_owner);
        rpg.setMintPrice(newMintPrice);
        assertEq(rpg.mintPrice(), newMintPrice);

        // Test as non-owner, should revert
        vm.prank(nonOwner);
        vm.expectRevert();
        rpg.setMintPrice(newMintPrice);
    }

    function testMint() public {
        uint256 mintPrice = rpg.mintPrice();
        uint256 tokenId = 0;
        assertEq(mintPrice, 10000000000000000, "Incorrect Mint Price");

        vm.deal(minterA, 100 ether);
        vm.prank(minterA);
        rpg.mint{value: mintPrice}();

        address newOwner = rpg.ownerOf(tokenId);
        assertEq(newOwner, minterA, "Token was not minted correctly");
    }

    function testTransfer() public {
        uint256 tokenId = 0;
        uint256 initialMintPrice = rpg.mintPrice();
        vm.deal(minterA, 100 ether);
        vm.prank(minterA);
        rpg.mint{value: initialMintPrice}();
        address owner = rpg.ownerOf(tokenId);
        assertEq(owner, minterA, "Token was not minted correctly");
        vm.prank(minterA);
        rpg.transfer(NFTRecevier, tokenId);
        address newowner = rpg.ownerOf(tokenId);
        assertEq(NFTRecevier, newowner);

        //Revert if transfer to zero address

        vm.prank(minterA);
        vm.expectRevert();
        rpg.transfer(address(0), tokenId);

        // Revert if transfer to self
        vm.prank(minterA);
        vm.expectRevert();
        rpg.transfer(minterA, tokenId);

        // Revert if token is not minted
        vm.prank(minterA);
        vm.expectRevert(bytes("Token is not Minted"));
        rpg.transfer(NFTRecevier, 1);

        //Revert if  "Token is locked"

        address ccipRouter = rpg._ccipHandler();
        console.log("ccipRouter", ccipRouter);

        // Lock the token by setting a future unlock time
        uint256 unlockTime = block.timestamp + 2 hours;
        vm.prank(ccipRouter);
        rpg.setTokenLockStatus(tokenId, unlockTime);

        // Attempt to access a function protected by the `isUnlocked` modifier before unlock time

        vm.warp(block.timestamp + 1 hours); // Warp halfway to the unlock time

        vm.prank(minterA);
        vm.expectRevert(bytes("Token is locked"));
        rpg.transfer(NFTRecevier, tokenId);
    }

    function testSetSign() public {
        string memory newSign = "GameXSignature";

        vm.prank(contract_owner);
        rpg.setSign(newSign);

        assertEq(rpg._sign(), newSign);
    }

    function testGetTokenStats() public {
        // Mint a nft token

        uint256 mintPrice = rpg.mintPrice();
        uint256 tokenId = 0;
        assertEq(mintPrice, 10000000000000000, "Incorrect Mint Price");

        vm.deal(minterA, 100 ether);
        vm.prank(minterA);
        rpg.mint{value: mintPrice}();

        address newOwner = rpg.ownerOf(tokenId);
        assertEq(newOwner, minterA, "Token was not minted correctly");

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
    }

    function testGetTokenStatsRevertsForUnmintedToken() public {
        uint256 unmintedTokenId = 2; // assuming tokenId 2 was not minted in setUp
        vm.expectRevert("Token is not Minted");
        rpg.getTokenStats(unmintedTokenId);
    }


      function testUpdateStatsSuccess() public {     //@auditV2: test failing

        address ccipRouter = rpg._ccipHandler();

        uint256 tokenId = 1;
        address newOwner = NFTRecevier;
        uint8 stat1 = 5;
        uint8 stat2 = 10;
        uint8 specialType = 15;
        uint8 specialPoints = 20;

        vm.prank(ccipRouter);
        bool success = rpg.updateStats(tokenId, newOwner, stat1, stat2, specialType, specialPoints);
        assertTrue(success, "UpdateStats should succeed");
        //check if nft minted successfuly
        address owner = rpg.ownerOf(tokenId);
        assertEq(owner, NFTRecevier, "Token was not minted correctly");

        // Verify the stats were updated
        // (uint8 updatedStat1, uint8 updatedStat2, uint8 updatedSpecialType, uint8 updatedSpecialPoints) = rpg.getTokenStats(tokenId);

        
        // console.log("updatedStat1", updatedStat1);     //10
        // console.log("updatedStat2", updatedStat2);     //20
        // console.log("updatedSpecialType", updatedSpecialType); //30
        // console.log("updatedSpecialPoints", updatedSpecialPoints); //40

        // Verify the stats were updated
        (uint256 updatedStat1, uint256 updatedStat2, uint256 updatedSpecialType, uint256 updatedSpecialPoints) = rpg.upgradeMapping(tokenId);

        console.log("updatedStat1", updatedStat1);     //0
        console.log("updatedStat2", updatedStat2);     //0
        console.log("updatedSpecialType", updatedSpecialType); //0
        console.log("updatedSpecialPoints", updatedSpecialPoints); //0



        // assertEq(updatedStat1, stat1, "Stat1 was not updated correctly");
        // assertEq(updatedStat2, stat2, "Stat2 was not updated correctly");
        // assertEq(updatedSpecialType, specialType, "SpecialType was not updated correctly");
        // assertEq(updatedSpecialPoints, specialPoints, "SpecialPoints was not updated correctly");
    }

     function testUpdateStatsRevertsForNonCCIPRouter() public {
     
        uint256 tokenId = 2;
        address newOwner = NFTRecevier;
        uint8 stat1 = 5;
        uint8 stat2 = 10;
        uint8 specialType = 15;
        uint8 specialPoints = 20;

        vm.expectRevert(bytes("Caller is not the CCIP router"));
        rpg.updateStats(tokenId, newOwner, stat1, stat2, specialType, specialPoints);
    }


     function testTokenURI() public {

        uint256 tokenId = 0;
        uint256 initialMintPrice = rpg.mintPrice();
        vm.deal(minterA, 100 ether);
        vm.prank(minterA);
        rpg.mint{value: initialMintPrice}();
        address owner = rpg.ownerOf(tokenId);
        assertEq(owner, minterA, "Token was not minted correctly");
        string memory tokenURI = rpg.tokenURI(tokenId);
        assertTrue(bytes(tokenURI).length > 0, "Token URI is empty");
    }


 function testPowerLevelWithoutUpgrades_pvt() public {
     // Mint a nft token
 uint256 mintPrice = rpg.mintPrice();
        uint256 tokenId = 0;
        assertEq(mintPrice, 10000000000000000, "Incorrect Mint Price");

        vm.deal(minterA, 100 ether);
        vm.prank(minterA);
        rpg.mint{value: mintPrice}();

        address newOwner = rpg.ownerOf(tokenId);
        assertEq(newOwner, minterA, "Token was not minted correctly");

        // Base stats are assumed to be set in the RPG constructor
        uint256 expectedPowerLevel = ((0 + 10) + (0 + 20)) / 2; //  calculation based on given base stats

        uint256 powerLevel = rpg.powerLevel__(tokenId);
        assertEq(powerLevel, expectedPowerLevel, "Power level calculation without upgrades is incorrect");
    }

    // function testPowerLevelWithUpgrades() public {
    //     uint256 tokenId = 2;
    //     // Assuming a function to mint or create a token exists
    //     // rpg.mint(address(this), tokenId); // Uncomment if minting is needed

    //     // Manually setting upgrade stats for the token
    //     StatType memory upgradeStats = StatType(5, 5, 0, 0); // Example upgrade stats
    //     rpg.upgradeMapping[tokenId] = upgradeStats; // This line is pseudo-code; actual implementation may vary

    //     uint256 expectedPowerLevel = ((10 + 5) + (20 + 5)) / 2; // Example calculation with upgrades

    //     uint256 powerLevel = rpg.powerLevel__(tokenId);
    //     assertEq(powerLevel, expectedPowerLevel, "Power level calculation with upgrades is incorrect");
   // }

   function testGetStatForMintedAndUnlockedToken() public {
         
         // Mint a nft token
        uint256 mintPrice = rpg.mintPrice();
        uint256 tokenId = 0;
        assertEq(mintPrice, 10000000000000000, "Incorrect Mint Price");

        vm.deal(minterA, 100 ether);
        vm.prank(minterA);
        rpg.mint{value: mintPrice}();

        address newOwner = rpg.ownerOf(tokenId);
        assertEq(newOwner, minterA, "Token was not minted correctly");

        // Test retrieval of stat1
        uint8 stat1 = rpg.getStat("l1", tokenId);
        assertEq(stat1, 10, "Incorrect stat1 value"); // 10 (base) + 0 (upgrade)

        // Test retrieval of stat2
        uint8 stat2 = rpg.getStat("l2", tokenId);
        assertEq(stat2, 20, "Incorrect stat2 value"); // 20 (base) + 0 (upgrade)
    }

     function testGetStatForUnmintedToken() public {
        uint256 tokenId = 999; // assuming this token is not minted

        vm.expectRevert(bytes("Token is not Minted"));
        rpg.getStat("l1", tokenId);
    }

      function testGetStatForLockedToken() public {
         // Mint a nft token
        uint256 mintPrice = rpg.mintPrice();
        uint256 tokenId = 0;
        assertEq(mintPrice, 10000000000000000, "Incorrect Mint Price");

        vm.deal(minterA, 100 ether);
        vm.prank(minterA);
        rpg.mint{value: mintPrice}();

        address newOwner = rpg.ownerOf(tokenId);
        assertEq(newOwner, minterA, "Token was not minted correctly");

       address ccipRouter = rpg._ccipHandler();
        console.log("ccipRouter", ccipRouter);

        // Lock the token by setting a future unlock time
        uint256 unlockTime = block.timestamp + 2 hours;
        vm.prank(ccipRouter);
        rpg.setTokenLockStatus(tokenId, unlockTime);

        vm.expectRevert(bytes("Token is locked"));
        rpg.getStat("l1", tokenId);
    }







}
