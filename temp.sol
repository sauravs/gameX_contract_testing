// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "../RPGItemNFT.sol";
import "../mocks/MockERC721Receiver.sol";

contract RPGItemNFTTest is DSTest {
    RPGItemNFT private rpgItemNFT;

    function setUp() public {
        rpgItemNFT = new RPGItemNFT();
    }

    function testConstructor() public {
        // Test statLabels
        (string memory label1, string memory label2) = rpgItemNFT.statLabels();
        assertEq(label1, "l1");
        assertEq(label2, "l2");

        // Test itemType
        assertEq(rpgItemNFT.itemType(), "weapon");

        // Test svgColors
        // Note: There's no direct way to test private arrays' length or content in Solidity
        // This part would ideally require internal access or a getter function to verify

        // Test colorRanges
        // Similar to svgColors, testing this would require internal access or a getter function

        // Test _ccipHandler
        assertEq(rpgItemNFT._ccipHandler(), 0xa1293A8bFf9323aAd0419E46Dd9846Cc7363D44b);

        // Test mintPrice
        assertEq(rpgItemNFT.mintPrice(), 10000000000000000);

        // Test _parentChainId
        // Note: There's no direct way to test private variables in Solidity
        // This part would ideally require internal access or a getter function to verify
    }
}