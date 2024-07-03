// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {RPGItemNFT} from "../src/RPG.sol";
import {RPGItemNFT_RECEIVER} from "../src/RPG_RECEIVER.sol";
import {CCIP_RPG_SENDER} from "../src/ccip_rpg_sender.sol";
import {CCIP_RPG_RECEIVER} from "../src/ccip_rpg_receiver.sol";
import {
    CCIPLocalSimulator,
    IRouterClient,
    WETH9,
    LinkToken,
    BurnMintERC677Helper
} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
import {CCIPLocalSimulatorFork, Register} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";

contract GameXTest is Test {
    RPGItemNFT public rpg; // rpg sender contract
    RPGItemNFT_RECEIVER public rpg_receiver; // rpg receiver contract

    CCIP_RPG_SENDER public ccipRpgSender;
    CCIP_RPG_RECEIVER public ccipRpgReceiver;

    address minterA;
    address minterB;

    address NFTRecevier;
    address contract_owner;
    address nonOwner;

    CCIPLocalSimulatorFork public ccipLocalSimulatorFork;

    Register.NetworkDetails sepoliaNetworkDetails;
    Register.NetworkDetails arbitrumNetworkDetails;

    uint256 sepoliaFork;
    uint256 arbSepoliaFork;

    // uint64 ethereumSapoliaBlockchainID = 11155111;
    // uint64 arbitrumSapoliaBlockchainID = 421614;

    uint64 chainSelectorETHSapolia = 16015286601757825753; //chain selector for ethereum sapolia
    uint64 chainSelectorArbitrumSApolia = 3478487238524512106; //chain selector for arbitrum sapolia

    function setUp() public {
        minterA = makeAddr("minterA");
        minterB = makeAddr("minterB");
        NFTRecevier = makeAddr("NFTRecevier");
        nonOwner = makeAddr("nonOwner");
        contract_owner = 0xB1293a8BFf9323AaD0419e46dd9846cC7363d44B;

        /////////////////////////////Contract deployment on fork network ////////////////////////////////////////////////////////

        string memory ETHEREUM_SEPOLIA_RPC_URL = vm.envString("ETHEREUM_SEPOLIA_RPC_URL");
        string memory ARBITRUM_SEPOLIA_RPC_URL = vm.envString("ARBITRUM_SEPOLIA_RPC_URL");

        sepoliaFork = vm.createSelectFork(ETHEREUM_SEPOLIA_RPC_URL); // we have created the fork and  we are now on Ethereum Sapolia
        arbSepoliaFork = vm.createFork(ARBITRUM_SEPOLIA_RPC_URL); // only created the fork and not selected yet

        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulatorFork));

        //Initiating the sepoliaNetworkDetails
        sepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid); // foundry under the hood auto grab the respective chain id ,and since we are now on ethereum saplio ,so blockchain id will be of ethereum sapolia

        // deploy the RPG.sol(sender) contract on the ethereum sapolia chain(source chain)

        rpg = new RPGItemNFT();

        // deploy the CCIP_RPG_SENDER.sol contract on the ethereum sapolia chain(source chain)

        ccipRpgSender = new CCIP_RPG_SENDER(sepoliaNetworkDetails.routerAddress, 900000);
        //console.logAddress(address(ccipRpgSender));

        //Switching the chain to Destination chain (receiver)
        vm.selectFork(arbSepoliaFork);

        // Initiating the arbitrum sapolia network details

        arbitrumNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);

        // deploy the RPG_RECEIVER.sol contract on the arbitrum sapolia chain(destination chain)

        rpg_receiver = new RPGItemNFT_RECEIVER();

        // deploy the CCIP_RPG_RECEIVER.sol contract on the arbitrum sapolia chain(destination chain)

        ccipRpgReceiver = new CCIP_RPG_RECEIVER(arbitrumNetworkDetails.routerAddress, 900000);
        //console.logAddress(address(ccipRpgReceiver));
    }

    function testConstructor() public {
        vm.selectFork(sepoliaFork);

        assertEq(rpg.statLabels(0), "l1");
        assertEq(rpg.statLabels(1), "l2");

        // Test itemType
        assertEq(rpg.itemType(), "weapon");

        // Test _ccipHandler
        assertEq(rpg._ccipHandler(), 0xF62849F9A0B5Bf2913b396098F7c7019b51A820a);

        // Test mintPrice
        assertEq(rpg.mintPrice(), 10000000000000000);
    }


 function testChangeCCIP() public {

        vm.selectFork(sepoliaFork);
        address newCCIPHandler = 0xA2293A8bFf9323AAd0419E46Dd9846Cc7363D44c;

        vm.prank(contract_owner);
        rpg.changeCCIP(newCCIPHandler);
        assertEq(rpg._ccipHandler(), newCCIPHandler);

    }

    function testchangeCCIPByNonOwnerReverts() public {

        vm.selectFork(sepoliaFork);
        address newCCIPHandler = 0xA2293A8bFf9323AAd0419E46Dd9846Cc7363D44c;

        vm.prank(nonOwner);
        vm.expectRevert();
        rpg.changeCCIP(newCCIPHandler);
    }




    function testSetMintPrice() public {

        vm.selectFork(sepoliaFork);
        rpg.owner();
        console.log("owner", rpg.owner());

        assertEq(rpg.owner(), contract_owner);

        uint256 newMintPrice = 2 ether;
        vm.prank(contract_owner);
        rpg.setMintPrice(newMintPrice);
        assertEq(rpg.mintPrice(), newMintPrice);

    }

    function testSetMintPriceByNonOwnerReverts() public {

        vm.selectFork(sepoliaFork);
        rpg.owner();
        //console.log("owner", rpg.owner());

        assertEq(rpg.owner(), contract_owner);

        uint256 newMintPrice = 2 ether;
        vm.prank(nonOwner);
        vm.expectRevert();
        rpg.setMintPrice(newMintPrice);

    }


      function testMint() public {

        vm.selectFork(sepoliaFork);
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

        vm.selectFork(sepoliaFork);
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

        vm.selectFork(sepoliaFork);
        string memory newSign = "GameXSignature";

        vm.prank(contract_owner);
        rpg.setSign(newSign);

        assertEq(rpg._sign(), newSign);
    }

    function testGetTokenStats() public {

        vm.selectFork(sepoliaFork);
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

        vm.selectFork(sepoliaFork);
        uint256 unmintedTokenId = 2; // assuming tokenId 2 was not minted in setUp
        vm.expectRevert("Token is not Minted");
        rpg.getTokenStats(unmintedTokenId);
    }



     function testTokenURI() public {

        vm.selectFork(sepoliaFork);
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

        vm.selectFork(sepoliaFork);
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


     function testGetStatForMintedAndUnlockedToken() public {

        vm.selectFork(sepoliaFork);
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

        vm.selectFork(sepoliaFork);
        uint256 tokenId = 999; // assuming this token is not minted

        vm.expectRevert(bytes("Token is not Minted"));
        rpg.getStat("l1", tokenId);
    }

    function testGetStatForLockedToken() public {

        vm.selectFork(sepoliaFork);
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

    
     function testGetSpecialForLockedToken() public {

        vm.selectFork(sepoliaFork);
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

        rpg.getSpecial(tokenId);
    }

    function testGetSpecialForUnmintedToken() public {

        vm.selectFork(sepoliaFork);
        uint256 tokenId = 999; // assuming this token is not minted

        vm.expectRevert(bytes("Token is not Minted"));
        rpg.getSpecial(tokenId);
    }



    function testGetSpecialForMintedAndUnlockedToken_Fail() public {

        vm.selectFork(sepoliaFork);

        // Mint a nft token
        uint256 mintPrice = rpg.mintPrice();
        uint256 tokenId = 0;
        assertEq(mintPrice, 10000000000000000, "Incorrect Mint Price");

        vm.deal(minterA, 100 ether);
        vm.prank(minterA);
        rpg.mint{value: mintPrice}();

        address newOwner = rpg.ownerOf(tokenId);
        assertEq(newOwner, minterA, "Token was not minted correctly");

        // Test retrieval of special stats
        (uint8 specialType, uint8 specialPoints) = rpg.getSpecial(tokenId);
        assertEq(specialType, 0, "Incorrect specialType value");
        assertEq(specialPoints, 0, "Incorrect specialPoints value");
    }


    function testCalculatePrice() public {
        rpg.StatType memory stat = rpg.StatType({
            stat1: 10,
            stat2: 20,
            specialType: 0,
            specialPoints: 0
        });

        uint256 expectedPrice = 1e18 / 100 * ((10 + 20) * 100) / 2 / 100;
        console.log("expectedPrice", expectedPrice);
        assertEq(rpg.calculatePrice(stat), expectedPrice);
    }

 function testUpgradeSuccess() public {

        vm.selectFork(sepoliaFork);
        // Mint a nft token
        uint256 mintPrice = rpg.mintPrice();
        uint256 tokenId = 0;
        assertEq(mintPrice, 10000000000000000, "Incorrect Mint Price");

        vm.deal(minterA, 100 ether);
        vm.prank(minterA);
        rpg.mint{value: mintPrice}();

        address newOwner = rpg.ownerOf(tokenId);
        assertEq(newOwner, minterA, "Token was not minted correctly");

        uint256 initialBalance = address(rpg).balance;
        uint256 BASE_PRICE_IN_MATIC = 1e18 / 100; //0.01 matic @auditV2: what is this for
        uint256 upgradeCost = BASE_PRICE_IN_MATIC; // Adjust this based on how you calculate the upgrade cost in your contract
        console.log("upgradeCost", upgradeCost);
        console.log("initialBalance", initialBalance);
        // // Send enough MATIC to cover the upgrade cost

        vm.deal(minterB, 100 ether);
        vm.startPrank(minterB);
        rpg.upgrade{value: 1 ether}(tokenId);
        vm.stopPrank();

        // StatType memory upgradedStat = rpg.upgradeMapping(tokenId);
        // assertTrue(upgradedStat.stat1 > 10 && upgradedStat.stat2 > 10, "Stats were not upgraded");
        // assertEq(address(rpg).balance, initialBalance + upgradeCost, "Upgrade cost was not transferred");
        // vm.stopPrank();
    }

    function testUpgradeForUnmintedToken() public {

        vm.selectFork(sepoliaFork);
        uint256 tokenId = 999; // Assuming this token is not minted
        uint256 BASE_PRICE_IN_MATIC = 1e18 / 100; //0.01 matic @auditV2: what is this for
        uint256 upgradeCost = BASE_PRICE_IN_MATIC;

        vm.deal(minterB, 1 ether);
        vm.startPrank(minterB);
        vm.expectRevert("Token is not Minted");
        rpg.upgrade{value: upgradeCost}(tokenId);
        vm.stopPrank();
    }

//   function testUpgradeWithInsufficientFunds() public {
       
//         vm.selectFork(sepoliaFork);
//         uint256 tokenId = 1;
//         uint256 insufficientFunds = RPG.BASE_PRICE_IN_MATIC / 2; // Half the required upgrade cost

//         vm.startPrank(address(this));
//         vm.expectRevert("insufficient fund for upgrade");
//         rpg.upgrade{value: insufficientFunds}(tokenId);
//         vm.stopPrank();
//     }

    // function testUpgradeForLockedToken() public {

    //     vm.selectFork(sepoliaFork);
    //     uint256 tokenId = 2;
    //     // Lock the token; assuming a function exists to lock the token
    //     // rpg.lockToken(tokenId, futureTimestamp); // Lock the token; adjust based on actual contract

    //     uint256 upgradeCost = RPG.BASE_PRICE_IN_MATIC;
    //     vm.deal(address(this), upgradeCost);
    //     vm.startPrank(address(this));
    //     vm.expectRevert("Token is locked");
    //     rpg.upgrade{value: upgradeCost}(tokenId);
    //     vm.stopPrank();
    // }





    function testCCIPFunctionalityForked() public {
        /*
       this test suit is to test successful transfer of minted NFT from Forked Source chain (Ethereum Sapolia) to Forked Destination chain (Arbitrum Sapolia)
           
        */

        //Switch to Source chain (sender) Ethereum Saplio Testnet and allow the destination chain to receive the NFT and also
        // to receive the ACK from destination chain (which will act as a source) all the arbitrium chain as source

        vm.selectFork(sepoliaFork);

        console.log("Chain ID for ethereum sapolia", block.chainid); //BlockChain ID for ethereum sapolia 11155111
            // chain selctor for ethereum sapolia 16015286601757825753

        vm.startPrank(address(this));
        ccipRpgSender.allowlistDestinationChain(arbitrumNetworkDetails.chainSelector, true);
        ccipRpgSender.allowlistSourceChain(arbitrumNetworkDetails.chainSelector, true);

        // check if it is set true
        bool isAllowed = ccipRpgSender.allowlistedDestinationChains(arbitrumNetworkDetails.chainSelector);
        assertEq(isAllowed, true, "Destination chain is not allowed");

        bool isAllowedSource = ccipRpgSender.allowlistedSourceChains(arbitrumNetworkDetails.chainSelector);
        assertEq(isAllowedSource, true, "Source chain is not allowed");

        vm.stopPrank();

        // Switch to Destination chain (receiver) Arbitrum Saplio Testnet and allow the source chain to send the NFT

        vm.selectFork(arbSepoliaFork);

        console.log("Chain ID for arbitrum sapolia", block.chainid); //BlockChain ID for arbitrum sapolia 421614
            // chain selctor for arbitrum sapolia 3478487238524512106

        vm.startPrank(address(this));
        ccipRpgReceiver.allowlistSourceChain(sepoliaNetworkDetails.chainSelector, true);
        ccipRpgReceiver.allowlistDestinationChain(sepoliaNetworkDetails.chainSelector, true);
        ccipRpgReceiver.allowlistSender(address(ccipRpgSender), true);

        // check if it is set true

        bool isAllowedSourceArb = ccipRpgReceiver.allowlistedSourceChains(sepoliaNetworkDetails.chainSelector);
        assertEq(isAllowedSourceArb, true, "Source chain is not allowed");

        bool isAllowedDestArb = ccipRpgReceiver.allowlistedDestinationChains(sepoliaNetworkDetails.chainSelector);
        assertEq(isAllowedDestArb, true, "Destination chain is not allowed");

        bool isAllowedSender = ccipRpgReceiver.allowlistedSenders(address(ccipRpgSender));
        assertEq(isAllowedSender, true, "Sender is not allowed");

        vm.deal(address(ccipRpgReceiver), 100 ether); // to pay for tx gas fee ccipreceiver
        console.log("ccipRpgSender balance", address(ccipRpgReceiver).balance);

        vm.stopPrank();

        //Switch to Source chain (sender) Ethereum Saplio Testnet and mint the NFT

        vm.selectFork(sepoliaFork);
        uint256 mintPrice = rpg.mintPrice();
        uint256 tokenId = 0;
        assertEq(mintPrice, 0.01 ether, "Mint price is not correct");

        vm.deal(minterA, 100 ether);
        vm.prank(minterA);
        rpg.mint{value: mintPrice}();

        address newOwner = rpg.ownerOf(tokenId);
        assertEq(newOwner, minterA, "Token was not minted correctly");

        // approve the minted NFT for transfer

        vm.prank(minterA);
        rpg.setApprovalForAll(address(ccipRpgSender), true);
        rpg.isApprovedForAll(minterA, address(ccipRpgSender));

        //for the purose of sending the transaction by ccip_sender contract as fee in native token
        vm.deal(address(ccipRpgSender), 100 ether);
        console.log("ccipRpgSender balance", address(ccipRpgSender).balance);

        vm.deal(minterA, 100 ether);
        console.log("minterA balance", minterA.balance);

        // Transfer the minted NFT from Source chain (Ethereum Sapolia) to Destination chain (Arbitrum Sapolia)

        vm.prank(minterA);
        ccipRpgSender.transferNft{value: 10 ether}(
            0, address(rpg), address(rpg_receiver), arbitrumNetworkDetails.chainSelector, address(ccipRpgReceiver)
        );

        // check if the NFT is transferred successfully by switching to destination chain

        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbSepoliaFork); // switch to destination chain
    }
}
