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

    //  function testChangeCCIP() public {
    //     address newCCIPHandler = address(3);

    //     // Test as owner
    //     cheats.prank(owner);
    //     rpgItemNFT.changeCCIP(newCCIPHandler);
    //     assertEq(rpgItemNFT._ccipHandler(), newCCIPHandler);

    //     // Test as non-owner, should revert
    //     cheats.prank(nonOwner);
    //     cheats.expectRevert("Ownable: caller is not the owner");
    //     rpgItemNFT.changeCCIP(newCCIPHandler);
    // }

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
}
