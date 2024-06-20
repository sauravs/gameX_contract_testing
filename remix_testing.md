
  
  Remix Testing
  -------------
  
 *  https://docs.chain.link/ccip/tutorials/send-arbitrary-data
 * https://docs.chain.link/ccip/supported-networks/v1_2_0/testnet#avalanche-fuji-ethereum-sepolia
 
 -> sending string text between smart contracts ->  Avalanche Fuji -> Ethereum sapolia
  
  ->you will pay CCIP fees in LINK, then you will pay CCIP fees in native gas
  
  
  Messenger.sol
 ----------------
 
 Step 1: Deployed Messenger.sol on fuji testnet (contract address : 0x9c81A8c3e54cb3DeAD5B6449C05483a70C453CAc )
  
  -> deploy messenger.sol on fuji -> router -> 0xF694E193200268f9a4868e4Aa017A0118C9a8177   link-> 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846
  
  destination chain selector -> 16015286601757825753
  
  
 Step 2: Enable "0x9c81A8c3e54cb3DeAD5B6449C05483a70C453CAc" contract to send CCIP messages to Ethereum Sepolia
 
       set allowlistDestinationChain = 16015286601757825753
	   
	   write to function allowlistDestinationChain()
      
	
	
	   
	   _destinationChainSelector:16015286601757825753
	   allowed:true
	   
	   Read to: allowlistedDestinationChains mapping(16015286601757825753) -> should return true
	   
	   
	   
 Step 3:    Deploy your receiver contract (Messenger.sol) on Ethereum Sepolia and enable receiving messages from your sender contract
 
       router address : 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59
	   link address : 0x779877A7B0D9E8603169DdbD7836e478b4624789
	   
	   
	   Deployed Messenger.sol contract address on sapolia is : 0x4E1e6A88778E8e3FdF3E0b26BC6ABf66481744C9 
	    
		->Enable your contract to receive CCIP messages from Avalanche Fuji
		
	   
	    function allowlistSourceChain(14767482510784806043,true)
		
		-> check if properly set by allowlistedSourceChains mapping..should retrun true
	   
 Step 4 : Enable messenger.sol (on sapolia here) to receive CCIP messages from the contract that you deployed on Avalanche Fuji 
 
             function allowlistSender(address _sender, bool allowed)
			 function allowlistSender(0x9c81A8c3e54cb3DeAD5B6449C05483a70C453CAc,true)
			 confirm if it set , by calling mapping allowlistSender
			 
  At this point, you have one sender contract on Avalanche Fuji and one receiver contract on Ethereum Sepolia



  Step 5: Switch back to Fuji (Sender)
  
  Send "Hello World!" from Avalanche Fuji
  
  sendMessagePayLINK(_destinationChainSelector,_receiver,_text);
  
  call sendMessagePayLINK(16015286601757825753,0x4E1e6A88778E8e3FdF3E0b26BC6ABf66481744C9,"Hello World!");
  
Getting following error:
 ````
Gas estimation errored with the following message (see below). The transaction execution will likely fail. Do you want to force sending? 
Error happened while trying to execute a function inside a smart contract
Eip838ExecutionError: execution reverted

````






