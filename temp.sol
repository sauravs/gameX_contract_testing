// Issue: The call to `setTokenLockStatus` within `transferNft` reverts because the caller is not recognized as the CCIP router.
// Solution: Ensure that the RPGItemNFT contract recognizes the CCIP_RPG_SENDER contract as a valid CCIP router.

// Step 1: Add a mechanism in RPGItemNFT to set and recognize a CCIP router address.
// Step 2: Update the RPGItemNFT contract to check if the caller of `setTokenLockStatus` is the recognized CCIP router.
// Step 3: Set the CCIP_RPG_SENDER address as the CCIP router in the RPGItemNFT contract before calling `transferNft`.

// Example fix in RPGItemNFT contract:

// Step 1: Add a state variable and setter for the CCIP router address
address private ccipRouterAddress;

function setCCIPRouterAddress(address _ccipRouterAddress) external onlyOwner {
    ccipRouterAddress = _ccipRouterAddress;
}

// Step 2: Modify the `setTokenLockStatus` function to check for CCIP router
function setTokenLockStatus(uint256 tokenId, bool lockStatus) external {
    require(msg.sender == ccipRouterAddress, "Caller is not the CCIP router");
    // existing logic to set token lock status
}

// Note: `onlyOwner` modifier is assumed to be part of the contract, restricting this function to the contract's owner.

// Step 3: In the deployment or initialization script, set the CCIP router address
// RPGItemNFT.setCCIPRouterAddress(CCIP_RPG_SENDER.address);