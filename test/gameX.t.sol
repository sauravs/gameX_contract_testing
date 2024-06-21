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
    address NFTRecevier;
    address contract_owner;
    address nonOwner;

    function setUp() public {
        minterA = makeAddr("minterA");
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
        
        vm.warp(block.timestamp + 1 hours);  // Warp halfway to the unlock time


        vm.prank(minterA);
        vm.expectRevert(bytes("Token is locked"));
        rpg.transfer(NFTRecevier, tokenId);

    }


//     function testTransferFrom() public {
//           uint256 tokenId = 0;
//         uint256 initialMintPrice = rpg.mintPrice();
//         vm.deal(minterA, 100 ether);
//         vm.prank(minterA);
//         rpg.mint{value: initialMintPrice}();
//         address owner = rpg.ownerOf(tokenId);
//         assertEq(owner, minterA, "Token was not minted correctly");
//         vm.prank(minterA);
//            rpg.transferFrom(minterA, NFTRecevier, tokenId);
//               address newowner = rpg.ownerOf(tokenId);
//         assertEq(NFTRecevier, newowner);
//     }





















}
