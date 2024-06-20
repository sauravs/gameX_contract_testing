// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import {Test, console } from "forge-std/Test.sol";
// import {SAMPLENFT} from "../src/sampleNFT.sol";
// //import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


// contract SAMPLENFTTEST is Test {

// SAMPLENFT public sampleNFT;
 
//  address owner;


// function setUp() public {

//     sampleNFT = new SAMPLENFT(msg.sender);
// }


//    function skiptestSafeMint() public {

//         uint256 tokenId = 0;
//         address someUser = makeAddr("someUser");

//         vm.prank(someUser);
//         sampleNFT.safeMint(someUser);

       
//         address newOwner = sampleNFT.ownerOf(tokenId);
//         assertEq(newOwner, someUser, "Token was not minted correctly");
//     }


// //////////////////////////////////////////////////////////////////////////////////////////

//         function testSafeMintRPG() public {
//             address someUser = makeAddr("someUser");


//              uint256 tokenId = 0;

//         vm.prank(someUser);
//         sampleNFT.safeMintRPG();

      
//         address newOwner = sampleNFT.ownerOf(tokenId);
//         console.log("newOwner",newOwner);
//         assertEq(newOwner, someUser, "Token was not minted correctly");
//     }


// //  function onERC721Received(address, address, uint256, bytes calldata) public override returns(bytes4) {
// //         return this.onERC721Received.selector;
// //     }



// }

