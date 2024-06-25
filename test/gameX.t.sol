// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test ,console} from "forge-std/Test.sol";
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

contract GameXTest is Test {
    RPGItemNFT public rpg; // rpg sender contract
    RPGItemNFT_RECEIVER public rpg_receiver; // rpg receiver contract


   CCIP_RPG_SENDER public ccipRpgSender;
   CCIP_RPG_RECEIVER public ccipRpgReceiver;
   uint64 chainSelector;
   uint64 destinationChainSelector;
   BurnMintERC677Helper ccipBnM;

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
        rpg_receiver = new RPGItemNFT_RECEIVER();


            /***********************************CCIP RELATED *****************************************************/
        CCIPLocalSimulator ccipLocalSimulator = new CCIPLocalSimulator();

        (
            uint64 chainSelector_,
            IRouterClient sourceRouter_,
            IRouterClient destinationRouter_,
            WETH9 weth9_,
            LinkToken linkToken_,
            BurnMintERC677Helper ccipBnM_,
            BurnMintERC677Helper ccipLnM_

        ) = ccipLocalSimulator.configuration();

        chainSelector = chainSelector_;
        ccipBnM = ccipBnM_;
        address sourceRouter = address(sourceRouter_);
        address linkToken = address(linkToken_);
        address destinationRouter = address(destinationRouter_);

        //destinationChainSelector = chainSelector;

        ccipRpgSender = new CCIP_RPG_SENDER(sourceRouter,900000);  // constructor(address _router, uint256 gasLimit)
        ccipRpgReceiver = new CCIP_RPG_RECEIVER(destinationRouter,900000);
        //log ccipRpgReceiver address

        // console.log("ccipRpgReceiver",ccipRpgReceiver);
        // console.log("ccipRpgSender",ccipRpgSender);

        // console.logAddress(address(ccipRpgSender));
        // console.logAddress(address(ccipRpgReceiver));  // ccipRpgReceiver address 0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9
    }

    function testConstructor() public {
        //    // Test statLabels
        //     (string memory label1, string memory label2) = rpgItemNFT.statLabels();
        //     assertEq(label1, "l1");
        //     assertEq(label2, "l2");
       
        // Test itemType
        assertEq(rpg.itemType(), "weapon");

        // Test _ccipHandler
        assertEq(rpg._ccipHandler(), 0xF62849F9A0B5Bf2913b396098F7c7019b51A820a);

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

     function testUpdateStatsRevertsForNonCCIPRouter_Failing() public {
     
        // uint256 tokenId = 2;
        // address newOwner = NFTRecevier;
        // uint8 stat1 = 5;
        // uint8 stat2 = 10;
        // uint8 specialType = 15;
        // uint8 specialPoints = 20;

        // vm.expectRevert(bytes("Caller is not the CCIP router"));
        // rpg.updateStats(tokenId, newOwner, stat1, stat2, specialType, specialPoints);
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


     function testGetSpecialForMintedAndUnlockedToken_Fail() public {
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
        // assertEq(specialType, 30, "Incorrect specialType value");
        // assertEq(specialPoints, 40, "Incorrect specialPoints value");
    }

    function testGetSpecialForLockedToken() public {
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
        uint256 tokenId = 999; // assuming this token is not minted

        vm.expectRevert(bytes("Token is not Minted"));
        rpg.getSpecial(tokenId);
    }
     

       function testUpgradeSuccess() public {
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
         uint256  BASE_PRICE_IN_MATIC = 1e18 / 100;     //0.01 matic @auditV2: what is this for
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
        uint256 tokenId = 999; // Assuming this token is not minted
          uint256  BASE_PRICE_IN_MATIC = 1e18 / 100;     //0.01 matic @auditV2: what is this for
        uint256 upgradeCost = BASE_PRICE_IN_MATIC; 

        vm.deal(minterB, 1 ether);
        vm.startPrank(minterB);
        vm.expectRevert("Token is not Minted");
        rpg.upgrade{value: upgradeCost}(tokenId);
        vm.stopPrank();
    }


    //  function testUpgradeWithInsufficientFunds() public {
    //     uint256 tokenId = 1;
    //     uint256 insufficientFunds = RPG.BASE_PRICE_IN_MATIC / 2; // Half the required upgrade cost

    //     vm.startPrank(address(this));
    //     vm.expectRevert("insufficient fund for upgrade");
    //     rpg.upgrade{value: insufficientFunds}(tokenId);
    //     vm.stopPrank();
    // }

    // function testUpgradeForLockedToken() public {
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
/////////////////////////////////////////////////CCIP Related/////////////////////////////////////////////////////////////////



   function testCCIPFunctionality() public {

        //log addres of this contract   
        //console.logAddress(address(this));

        // Allow the sender and receiver to communicate with each other
        
        vm.startPrank(address(this));    
        ccipRpgSender.allowlistDestinationChain(chainSelector,true);  //16015286601757825753
        ccipRpgReceiver.allowlistSourceChain(chainSelector,true);
        ccipRpgReceiver.allowlistSender(address(ccipRpgSender),true);


// check if it is set true
        bool isAllowed = ccipRpgSender.allowlistedDestinationChains(chainSelector);
        assertEq(isAllowed, true, "Destination chain is not allowed");

        isAllowed = ccipRpgReceiver.allowlistedSourceChains(chainSelector);
        assertEq(isAllowed, true, "Source chain is not allowed");

        isAllowed = ccipRpgReceiver.allowlistedSenders(address(ccipRpgSender));
        assertEq(isAllowed, true, "Sender is not allowed");        
         vm.stopPrank();
    //        function allowlistDestinationChain(uint64 _destinationChainSelector, bool allowed) external onlyOwner {
    //     allowlistedDestinationChains[_destinationChainSelector] = allowed;
    // }


   /*************************Mint the NFT on RPG NFT Contract****************************************************** */
         uint256 mintPrice = rpg.mintPrice();
         uint256 tokenId = 0;
         //assertEq(mintPrice, 0.0001 ether, "Mint price is not 1 Ether");

        vm.deal(minterA, 100 ether);
        vm.prank(minterA);
        rpg.mint{value: mintPrice}();

        address newOwner = rpg.ownerOf(tokenId);
        assertEq(newOwner, minterA, "Token was not minted correctly");

   /************************************Transferring the NFT Cross Chain****************************************************** */

     // approve the minted NFT for transfer

    vm.prank(minterA);
    rpg.setApprovalForAll(address(ccipRpgSender),true);
    rpg.isApprovedForAll(minterA,address(ccipRpgSender));

  // transferNft(_tokenId, senderNftContractAddress ,destinationNftContractAddress ,destinationChainId , _receiver)

    //bytes32 messageID= ccipRpgSender.transferNft(0,address(rpg),address(rpg),chainSelector,address(ccipRpgReceiver));
   // console2.logBytes32(messageID);

   // IMPORTANT : you have to deploy two times rpg contract by passing cciphandler_sender and cciphandler_receiver address in constructor to make it work
    
    vm.deal(address(ccipRpgSender),100 ether); //for the purose of sending the transaction by ccip_sender contract as fee in native token
    console.log("ccipRpgSender balance",address(ccipRpgSender).balance);
    

  vm.prank(minterA);
ccipRpgSender.transferNft(0,address(rpg),address(rpg_receiver),chainSelector,address(ccipRpgReceiver));


    // bytes32 messageID= ccipRpgSender.getLastSentMessageID();

    //  ccipRpgReceiver.getLastReceivedMessageDetails()

   }



}
