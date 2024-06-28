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

    Register.NetworkDetails  sepoliaNetworkDetails;
    Register.NetworkDetails  arbitrumNetworkDetails;

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

        sepoliaFork = vm.createSelectFork(ETHEREUM_SEPOLIA_RPC_URL); // we are created the fork and  we are now on Ethereum Sapolia
        arbSepoliaFork = vm.createFork(ARBITRUM_SEPOLIA_RPC_URL); // only created the fork and not selected yet

        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulatorFork));

        //Initiating the sepoliaNetworkDetails
        sepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid); // foundry under the hood auto grab the respective chain id ,and since we are now on ethereum saplio ,so blockchain id will be of ethereum sapolia

        // deploy the RPG.sol(sender) contract on the ethereum sapolia chain(source chain)

        rpg = new RPGItemNFT();

        // deploy the CCIP_RPG_SENDER.sol contract on the ethereum sapolia chain(source chain)

        ccipRpgSender = new CCIP_RPG_SENDER(sepoliaNetworkDetails.routerAddress, 900000);
        console.logAddress(address(ccipRpgSender));

        //Switching the chain to Destination chain (receiver)
        vm.selectFork(arbSepoliaFork); 


        // Initiating the arbitrum sapolia network details  

        arbitrumNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid); 

        // deploy the RPG_RECEIVER.sol contract on the arbitrum sapolia chain(destination chain)

        rpg_receiver = new RPGItemNFT_RECEIVER();

        // deploy the CCIP_RPG_RECEIVER.sol contract on the arbitrum sapolia chain(destination chain)

        ccipRpgReceiver = new CCIP_RPG_RECEIVER(arbitrumNetworkDetails.routerAddress, 900000);
        console.logAddress(address(ccipRpgReceiver)); 

        
    }

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


        // Transfer the minted NFT from Source chain (Ethereum Sapolia) to Destination chain (Arbitrum Sapolia)

        vm.prank(minterA);
        ccipRpgSender.transferNft(0, address(rpg), address(rpg_receiver), arbitrumNetworkDetails.chainSelector, address(ccipRpgReceiver));



        vm.selectFork(arbSepoliaFork); //Destination chain (receiver)

        //console log blockchain id

        console.log("Chain ID for arbitrum sapolia", block.chainid); //BlockChain ID for arbitrum sapolia 421614
            // chain selctor for arbitrum sapolia 3478487238524512106
    }
}
