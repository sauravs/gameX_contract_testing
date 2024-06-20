import "ds-test/test.sol";
import "./RPG.sol";

contract RPGTest is DSTest {
    RPG rpg;
    address constant testAddress = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2; // Replace with a valid address

    function setUp() public {
        rpg = new RPG();
    }

    function testUpdateStats() public {
        uint256 tokenId = 0; // Assuming the first minted token has an ID of 0
        uint8 stat1 = 10;
        uint8 stat2 = 20;
        uint8 specialType = 1;
        uint8 specialPoints = 5;

        bool result = rpg.updateStats(tokenId, testAddress, stat1, stat2, specialType, specialPoints);
        assertTrue(result, "updateStats did not return true");

        // Assuming you have getter functions for the stats
        assertEq(rpg.getStat1(tokenId), stat1, "Stat1 was not updated correctly");
        assertEq(rpg.getStat2(tokenId), stat2, "Stat2 was not updated correctly");
        assertEq(rpg.getSpecialType(tokenId), specialType, "SpecialType was not updated correctly");
        assertEq(rpg.getSpecialPoints(tokenId), specialPoints, "SpecialPoints was not updated correctly");
    }
}