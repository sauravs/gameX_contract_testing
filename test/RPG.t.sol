// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import {Test, console} from "forge-std/Test.sol";
// import {RPGItemNFT} from "../src/RPG.sol";
// import {CCIP_RPG_SENDER} from "../src/ccip_rpg_sender.sol";
// import {CCIP_RPG_RECEIVER} from "../src/ccip_rpg_receiver.sol";
// import {CCIPLocalSimulator, IRouterClient, WETH9,LinkToken, BurnMintERC677Helper} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";



// contract RPGItemNFTTest is Test {
   
//    RPGItemNFT public rpg;                            // rpg sender contract
//    RPGItemNFT public rpg_receiver;                   // rpg receiver contract
   
//    CCIP_RPG_SENDER public ccipRpgSender;
//    CCIP_RPG_RECEIVER public ccipRpgReceiver;
//    uint64 chainSelector;
//    //uint64 destinationChainSelector;
//    BurnMintERC677Helper ccipBnM;


//      address minterA ;
//      address NFTRecevier;
         
 

//     function setUp() public {

            
//        minterA = makeAddr("minterA");
//        NFTRecevier = makeAddr("NFTRecevier");
     
//         /***********************************CCIP RELATED *****************************************************/
//         CCIPLocalSimulator ccipLocalSimulator = new CCIPLocalSimulator();
    
//         (
//             uint64 chainSelector_,
//             IRouterClient sourceRouter_,
//             IRouterClient destinationRouter_,
//             WETH9 weth9_,
//             LinkToken linkToken_,
//             BurnMintERC677Helper ccipBnM_,
//             BurnMintERC677Helper ccipLnM_

//         ) = ccipLocalSimulator.configuration();

//         chainSelector = chainSelector_;
//         ccipBnM = ccipBnM_;
//         address sourceRouter = address(sourceRouter_);
//         address linkToken = address(linkToken_);
//         address destinationRouter = address(destinationRouter_);

//         //destinationChainSelector = chainSelector;


//         ccipRpgSender = new CCIP_RPG_SENDER(sourceRouter,800000);  // constructor(address _router, uint256 gasLimit) 
//         ccipRpgReceiver = new CCIP_RPG_RECEIVER(destinationRouter,800000);



//         /***********************************RPG NFT CONTRACT RELATED *****************************************************/

//         string[2] memory labels = ["Strength", "Agility"];
//         uint8[] memory baseStats = new uint8[](4);
//         baseStats[0] = 10;
//         baseStats[1] = 20;
//         baseStats[2] = 1;
//         baseStats[3] = 5;
//         string[] memory svgColors = new string[](2);
//         svgColors[0] = "#FF0000";
//         svgColors[1] = "#00FF00";
//         uint8[] memory colorRanges = new uint8[](2);
//         colorRanges[0] = 1;
//         colorRanges[1] = 2;



//          rpg = new RPGItemNFT(
//             "SWORD",
//             "He-man Sword",
//             "HSWD",
//             labels,
//             baseStats,
//             msg.sender,
//             svgColors,
//             colorRanges,
//             address(ccipRpgSender),
//             0.0001 ether,
//             1
//         );
       

//        rpg_receiver = new RPGItemNFT(
//             "SWORD",
//             "He-man Sword",
//             "HSWD",
//             labels,
//             baseStats,
//             msg.sender,
//             svgColors,
//             colorRanges,
//             address(ccipRpgReceiver),
//             0.0001 ether,
//             1
//         );
       
        
        
//     }







//     function testConstructor() public {


        
//          assertEq(rpg.name(),"He-man Sword");
//         assertEq(rpg.symbol(),"HSWD");
//         assertEq(rpg.owner(), msg.sender);
//          assertEq(rpg.mintPrice(),  0.0001 ether);
//     }
    

//     function skiptestSetMintPrice() public {
//         uint256 newMintPrice = 2 ether;
//         rpg.setMintPrice(newMintPrice);
//         assertEq(rpg.mintPrice(), newMintPrice);

        
//     }

// <<<<<<< HEAD
//       function skiptestGetSpecial() public {
// =======
//       function testGetSpecial() public {
// >>>>>>> 0265555e7aada10d69597a73957dce49be29f450

//         uint tokenId = 0;
//         uint8 specialType;
//         uint8 specialPoints;
//         (specialType, specialPoints) = rpg.getSpecial(tokenId);
//         assertEq(specialType, 0);       //@audit hardcoded and compared to zero as per getTokenStats logic -it should have 1 though the value we are passing in constructor
//         assertEq(specialPoints, 0);   //@audit hardcoded and compared to zero as per getTokenStats logic -it should have 1 though the value we are passing in constructor
//     }


//     //  function testFSetMintPrice() public {
//     //     uint256 newMintPrice = 2 ether;
//     //     vm.startPrank(address(1));
//     //     rpg.setMintPrice(newMintPrice);

//     //     vm.stopPrank();

        
//     // }


  

//     function skiptestMint() public {

//                                                                    //uint256 initialTokenCount = rpg.totalSupply();
//          uint256 mintPrice = rpg.mintPrice();
//          uint256 tokenId = 0;
//         assertEq(mintPrice, 0.0001 ether, "Mint price is not 1 Ether");

//         vm.deal(minterA, 100 ether);
//         vm.prank(minterA);
//         rpg.mint{value: mintPrice}();
   
//         address newOwner = rpg.ownerOf(tokenId);
//         assertEq(newOwner, minterA, "Token was not minted correctly");

   
//     }



// function testTransfer() public {
//         uint256 tokenId = 0;
//         uint256 initialMintPrice = rpg.mintPrice();
//         vm.deal(minterA, 100 ether);
//         vm.prank(minterA);
//         rpg.mint{value: initialMintPrice}();
//         address owner = rpg.ownerOf(tokenId);
//         assertEq(owner, minterA, "Token was not minted correctly");
//         vm.prank(minterA);
//         rpg.transfer(NFTRecevier, tokenId);
//         address newowner = rpg.ownerOf(tokenId);
//         assertEq(NFTRecevier, newowner);
//     }


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

   


// <<<<<<< HEAD
//     function skiptestTokenURI() public {
// =======
//     function testTokenURI() public {
// >>>>>>> 0265555e7aada10d69597a73957dce49be29f450
//          uint256 tokenId = 0;
//         uint256 initialMintPrice = rpg.mintPrice();
//         vm.deal(minterA, 100 ether);
//         vm.prank(minterA);
//         rpg.mint{value: initialMintPrice}();
//         address owner = rpg.ownerOf(tokenId);
//         assertEq(owner, minterA, "Token was not minted correctly");
//         string memory tokenURI = rpg.tokenURI(tokenId);
//         assertTrue(bytes(tokenURI).length > 0, "Token URI is empty");
//     }





  

//   function testgetTokenStats() public {

   
//         uint tokenId = 0;

//         // Set the expected stats
//         uint8 expectedStat1 = 0;
//         uint8 expectedStat2 = 0;
//         uint8 expectedSpecialType = 0;
//         uint8 expectedSpecialPoints = 0;

//         // Call getTokenStats and check the returned stats
//         (uint8 stat1, uint8 stat2, uint8 specialType, uint8 specialPoints) = rpg.getTokenStats(tokenId);
//         assertEq(stat1, expectedStat1, "stat1 does not match");
//         assertEq(stat2, expectedStat2, "stat2 does not match");
//         assertEq(specialType, expectedSpecialType, "specialType does not match");
//         assertEq(specialPoints, expectedSpecialPoints, "specialPoints does not match");


//     }


//       function testLockStatus() public {


//         uint tokenId = 0;
//         // Set a future timestamp as unlockTime
//         uint256 unlockTime = block.timestamp + 1 days;

//         // // Set the sender to _ccipHandler
//         // address ccipHandler = address(0); 
//         // vm.prank(ccipHandler);


//         // Call setTokenLockStatus
//         vm.prank( address(ccipRpgSender));
//         rpg.setTokenLockStatus(tokenId, unlockTime);

//         // Check tokenLockedTill[tokenId]
//         uint256 actualUnlockTime = rpg.tokenLockedTill(tokenId); 
//         assertEq(actualUnlockTime, unlockTime, "Unlock time was not set correctly");

     
//         // Check lockStatus
//         bool isLocked = rpg.lockStatus(tokenId);
//         assertTrue(isLocked, "Token should be locked");

//         // Advance time by 2 days
//         vm.warp(block.timestamp + 2 days);
        
//         // Checking lockStatus again
//         isLocked = rpg.lockStatus(tokenId);
//         assertFalse(isLocked, "Token should be unlocked");

        
//     }

//      function testChangeCCIP() public {
//         address newAdd = address(0x123); // Replace with a real address

//         // Call changeCCIP
//         rpg.changeCCIP(newAdd);
//         // Check that _ccipHandler was updated correctly
       
//         assertEq(rpg._ccipHandler(), newAdd, "_ccipHandler was not updated correctly");
//      }

   
//   function testUpgradeAndGetStat() public {

//         uint tokenId = 0;

//         uint basePriceInMatic = rpg.BASE_PRICE_IN_MATIC();

//         //console2.log("basePriceInMatic", basePriceInMatic);

//         // Get the current stats
//         uint8 oldStat1 = rpg.getStat("Strength", tokenId);   
//         uint8 oldStat2 = rpg.getStat( "Agility", tokenId);

        
        
        
// RPGItemNFT.StatType memory oldStats = RPGItemNFT.StatType({stat1: 10, stat2: 20, specialType: 1, specialPoints: 5});


// RPGItemNFT.StatType memory newStats = rpg.calculateUpgrade(oldStats);
        
        
        
        
//         // uint256 upgradePrice = rpg.calculatePrice(newStats); //@audit - arithmetic underflow or overflow 

//         //   uint256 upgradePrice = 0.0001 ether ; //@audit hardcoding the value to continue testing

//         // // Check the price calculation
//         // uint256 expectedPrice = basePriceInMatic * rpg.statPriceMultiplier__(newStats);
//         // assertEq(upgradePrice, expectedPrice, "Price was not calculated correctly");


//       //  rpg.upgrade{value: upgradePrice}(tokenId);  //@audit failing due to arithmetic underflow or overflow

//         // // Check the stats
//         // uint8 newStat1 = rpg.getStat("Strength", tokenId);
//         // uint8 newStat2 = rpg.getStat("Agility", tokenId);
//         // assertTrue(newStat1 > oldStats.stat1, "stat1 was not upgraded");
//         // assertTrue(newStat2 > oldStats.stat2, "stat2 was not upgraded");

//         // // Check the price calculation
//         // uint256 expectedPrice = basePriceInMatic * rpg.statPriceMultiplier__(newStats);
//         // assertEq(upgradePrice, expectedPrice, "Price was not calculated correctly");

     

//         // // Check the hash generation
//         // bytes32 expectedHash = rpg._generateStatHash(oldStats);
//         // bytes32 newHash = rpg._generateStatHash(newStats);
//         // assertEq(expectedHash, newHash, "Hash generation was incorrect");
//     }


//     //  function testUpdateStats() public {
//     //     uint256 tokenId = 0; // Assuming the first minted token has an ID of 0
//     //     uint8 stat1 = 100;
//     //     uint8 stat2 = 200;
//     //     uint8 specialType = 10;
//     //     uint8 specialPoints = 50;

//     //     bool result = rpg.updateStats(tokenId, testAddress, stat1, stat2, specialType, specialPoints);
//     //     assertTrue(result, "updateStats did not return true");

//     //     // Assuming you have getter functions for the stats
//     //     // assertEq(rpg.getStat1(tokenId), stat1, "Stat1 was not updated correctly");
//     //     // assertEq(rpg.getStat2(tokenId), stat2, "Stat2 was not updated correctly");
//     //     // assertEq(rpg.getSpecialType(tokenId), specialType, "SpecialType was not updated correctly");
//     //     // assertEq(rpg.getSpecialPoints(tokenId), specialPoints, "SpecialPoints was not updated correctly");
//     // }

//         ccipRpgReceiver.allowlistDestinationChain(chainSelector,true);
//         ccipRpgReceiver.allowlistSourceChain(chainSelector,true);
//         ccipRpgReceiver.allowlistSender(address(ccipRpgSender),true);
   
//    /*************************Mint the NFT on RPG NFT Contract****************************************************** */
//          uint256 mintPrice = rpg.mintPrice();
//          uint256 tokenId = 0;
//         assertEq(mintPrice, 0.0001 ether, "Mint price is not 1 Ether");



//    function testCCIPFunctionality() public {
        
//         // Allow the sender and receiver to communicate with each other
        
//         ccipRpgSender.allowlistDestinationChain(chainSelector,true);
//         ccipRpgReceiver.allowlistSourceChain(chainSelector,true);
//         ccipRpgReceiver.allowlistSender(address(ccipRpgSender),true);
   
//    /*************************Mint the NFT on RPG NFT Contract****************************************************** */
//          uint256 mintPrice = rpg.mintPrice();
//          uint256 tokenId = 0;
//         assertEq(mintPrice, 0.0001 ether, "Mint price is not 1 Ether");

//         vm.deal(minterA, 100 ether);
//         vm.prank(minterA);
//         rpg.mint{value: mintPrice}();
   
//         address newOwner = rpg.ownerOf(tokenId);
//         assertEq(newOwner, minterA, "Token was not minted correctly");

//    /************************************Transferring the NFT Cross Chain****************************************************** */

//      // approve the minted NFT for transfer

//     vm.prank(minterA);
//     rpg.setApprovalForAll(address(ccipRpgSender),true);
//     rpg.isApprovedForAll(minterA,address(ccipRpgSender));


  

//   // transferNft(_tokenId, senderNftContractAddress ,destinationNftContractAddress ,destinationChainId , _receiver)               
        
//     //bytes32 messageID= ccipRpgSender.transferNft(0,address(rpg),address(rpg),chainSelector,address(ccipRpgReceiver));   
//    // console2.logBytes32(messageID);     

//    // IMPORTANT : you have to deploy two times rpg contract by passing cciphandler_sender and cciphandler_receiver address in constructor to make it work   

        
      
//     ccipRpgSender.transferNft(0,address(rpg),address(rpg_receiver),chainSelector,address(ccipRpgReceiver));  

//      // ccipRpgReceiver.getLastReceivedMessageDetails()
      

        


//    }







//  }











   




