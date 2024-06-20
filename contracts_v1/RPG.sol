

//   * can transfer the NFT
//   * Not burnable   // but  erc721burnable imported
					   

                        // @audit remove ERC721Burnable


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract RPGItemNFT is ERC721, ERC721Burnable, Ownable {
 
 ////////////////////////////////////////////////////////////D//////////////////////////////////////////////////////////////////////////////
   
    uint256 public mintPrice;
    uint256 private _nextTokenId;
    using Strings for uint256;
    string public itemType;
    string[2] public statLabels;
    string public itemImage;
    string public lockedItemImage =
        "https://plum-liable-mastodon-450.mypinata.cloud/ipfs/QmaXD4NLN9hn5cb9jTd78faMvU3RNmf34gvhLGsnq67zs3";
    string[] private svgColors;
    uint8[] private colorRanges;
    address public _ccipHandler;   //@audit : made it public for testing purpose ,also better to make it public anyways to validate via UX
    uint256 private _parentChainId;
 ////////////////////////////////////////////////////////////D//////////////////////////////////////////////////////////////////////////////


    event NftMinted(
        address indexed recipient,
        uint256 indexed tokenId,
        uint256 indexed timestamp
    );
    
    event Transfer(address indexed sender, uint256 indexed amount);
 ////////////////////////////////////////////////////////////D//////////////////////////////////////////////////////////////////////////////


    uint256 public BASE_PRICE_IN_MATIC = 1e18 / 100;           //@audit for testing purpose making it public and removing constants                // 1 % of 1 ether
    // No change to this stat.
    struct StatType {
        uint8 stat1;                  
        uint8 stat2;
        uint8 specialType;
        uint8 specialPoints;
    }

    StatType baseStat;
 ////////////////////////////////////////////////////////////D//////////////////////////////////////////////////////////////////////////////


    mapping(uint256 => StatType) public upgradeMapping;   // tokenID->StatType  // @audit made it public for testing purpose

    mapping(bytes32 => StatType) public newStatMap;      // hash of StatType -> StatType   // @audit made it public for testing purpose

    mapping(uint256 => uint256) public tokenLockedTill;  // ccip related // tokenID -> unlockTime //@audit should be make public to validate via UX how much time left //also made public for testing purpose
 ////////////////////////////////////////////////////////////D//////////////////////////////////////////////////////////////////////////////


    modifier onlyCCIPRouter() {
        require(msg.sender == _ccipHandler, "Caller is not the CCIP router");
        _;
    }
///////////////////////////////////////////////////////////////D///////////////////////////////////////////////////////////////////////////

    //  change the name to lockStatus TODO

    function lockStatus(uint256 tokenId) public view returns (bool) {
        return (tokenLockedTill[tokenId] > block.timestamp);
    }
///////////////////////////////////////////////////////////////D//////////////////////////////////////////////////////////////////////////

    // chaneg the isUnlocked to  mod and apply to all trasnsfer , TraansferFrom ,upgrade, tokenUri wale me ternry
    modifier isUnlocked(uint256 tokenId) {
        require(tokenLockedTill[tokenId] <= block.timestamp, "Token is locked");
        _;
    }
/////////////////////////////////////////////////////////////////D//////////////////////////////////////////////////////////////
    function setTokenLockStatus(uint256 tokenId, uint256 unlockTime)
        public
        onlyCCIPRouter
    {
        tokenLockedTill[tokenId] = unlockTime;
    }
//////////////////////////////////////////////////////////////////D/////////////////////////////////////////////////////////////////
    constructor(
        string memory itemType__,
        string memory tokenName__,
        string memory tokenSymbol__,
        string[2] memory labels__,      // labels is name of statstype //@audit -> labels 0 ,1,2 3 labels?
        uint8[] memory baseStat__,
        address initialOwner__,
        string[] memory svgColors__,    // svgColors   0-10 : #EFFF 
        uint8[] memory colorRanges__,   // colorRanges : 0-10-20-30
        address ccipHandler,
        uint256 mintPrice__,
        uint256 parentChainId__
    ) ERC721(tokenName__, tokenSymbol__) Ownable(initialOwner__) {
        baseStat.stat1 = baseStat__[0];
        baseStat.stat2 = baseStat__[1];
        baseStat.specialType = baseStat__[2];
        baseStat.specialPoints = baseStat__[3];
        statLabels = labels__;
        itemType = itemType__;
        colorRanges = colorRanges__;
        svgColors = svgColors__;
        _ccipHandler = ccipHandler;
        mintPrice = mintPrice__;
        _parentChainId = parentChainId__;
    }
///////////////////////////////////////////////////////////D////////////////////////////////////////////////////////////////////////
    function changeCCIP(address newAdd) external {       // @audit it should not be open for public
        _ccipHandler = newAdd;
    }
////////////////////////////////////////////////////////////D///////////////////////////////////////////////////////////////////////
    receive() external payable {
        emit Transfer(msg.sender, msg.value);
    }
///////////////////////////////////////////////////////////////D//////////////////////////////////////////////////////////////////////////////
    function setMintPrice(uint256 _mintPrice) public {               //@audit set mint price should not be open for public?
        require(_mintPrice >= 0, "mint price must be greater then 0");
        mintPrice = _mintPrice;
    }
//////////////////////////////////////////////////////////////////D/////////////////////////////////////////////////////////////////
    function getTokenStats(uint256 tokenId)                       //@audit what is the purpose of this,confusion with getStats()
        public
        view
        returns (
            uint8,
            uint8,
            uint8,
            uint8
        )
    {
        StatType memory stats = upgradeMapping[tokenId];
        return (
            stats.stat1,
            stats.stat2,
            stats.specialType,
            stats.specialPoints
        );
    }
/////////////////////////////////////////////////////////////////////D///////////////////////////////////////////////////////////////////////
   
   // @audit : function updateStats() -> anyone who knows the token id would be able to update the stats of the token ,not desirable
   
    function updateStats(                                        //ccip related
        uint256 tokenId,
        address newOwner,
        uint8 stat1,
        uint8 stat2,
        uint8 specialType,
        uint8 specialPoints
    ) external returns (bool)  {
        require(newOwner != address(0), "Invalid new owner address");

        address currentOwner = ownerOf(tokenId);

        if (currentOwner == address(0)) {                               
            _safeMint(newOwner, tokenId);
            tokenLockedTill[tokenId] = 0;                                     
            emit NftMinted(newOwner, tokenId, block.timestamp);
        }

        StatType memory tokenStats = upgradeMapping[tokenId];
        tokenStats.stat1 = stat1;
        tokenStats.stat2 = stat2;
        tokenStats.specialType = specialType;
        tokenStats.specialPoints = specialPoints;

        return true;
    }
///////////////////////////////////////////////////////////////////////D/////////////////////////////////////////////////////////////////////
   
  
   
    function mint() public payable {
        // require(                        // @audit 
        //     _parentChainId == block.chainid,
        //     string(
        //         abi.encodePacked(
        //             "Mint is not allowed on this chain , You can mint on ChainId : ",
        //             _parentChainId.toString()
        //         )
        //     )
        // );
        require(msg.value == mintPrice, "Insufficient Ether sent for minting");
        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
        tokenLockedTill[tokenId] = 0;
        emit NftMinted(msg.sender, tokenId, block.timestamp);
    }

/////////////////////////////////////////////////////////////////////D///////////////////////////////////////////////////////////////////////
    

    function generateSVG(                                                         // used in tokenURI
        string memory color,
        string memory stat1,
        string memory stat2,
        string memory image,
        string memory name
    ) internal pure returns (string memory imgSVG) {
        imgSVG = string(
            abi.encodePacked(
                "<svg xmlns='http://www.w3.org/2000/svg' version='1.1' xmlns:xlink='http://www.w3.org/1999/xlink' xmlns:svgjs='http://svgjs.com/svgjs' width='500' height='500' preserveAspectRatio='none' viewBox='0 0 500 500'> <rect width='100%' height='100%' fill='",
                color,
                stat1,
                stat2,
                name,
                "' />",
                "<image x='50%' y='50%' font-size='128' dominant-baseline='middle' text-anchor='middle'>",
                image,
                "</image>",
                "</svg>"
            )
        );
    }

//////////////////////////////////////////////////////////////D//////////////////////////////////////////////////////////////////////////////

    function ownerOf(uint256 tokenId)   
        public
        view
        virtual
        override
        returns (address)
    {
        return _ownerOf(tokenId);
    }

//////////////////////////////////////////////////////////////ND/////////////////////////////////////////////////////////////////////////////

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        bool tokenLockStatus = lockStatus(tokenId);
        string memory imgSVG = generateSVG(
            tokenLockStatus ? "#808080" : powerLevelColor(tokenId),
            tokenLockStatus
                ? "??"
                : Strings.toString(getStat(statLabels[0], tokenId)),
            tokenLockStatus
                ? "??"
                : Strings.toString(getStat(statLabels[1], tokenId)),
            tokenLockStatus ? lockedItemImage : itemImage,
            name()
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "ETH Watching SVG",',
                        '"description": "An Automated ETH tracking SVG",',
                        '"image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(imgSVG)),
                        '"}'
                    )
                )
            )
        );

        string memory finalTokenURI = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
        return finalTokenURI;
    }
//////////////////////////////////////////////////////////////////D//////////////////////////////////////////////////////////////////////////
    
    
    function upgrade(uint256 tokenId) public payable isUnlocked(tokenId) {
        StatType memory previousStat = upgradeMapping[tokenId];
        StatType memory newStat = calculateUpgrade(previousStat);
        require(msg.value >= calculatePrice(newStat));
        upgradeMapping[tokenId] = newStat;
    }


/////////////////////////////////////////////////////////////////D///////////////////////////////////////////////////////////////////////////
    
    //@audit Function declared as pure, but this expression (potentially) reads from the environment or state and thus requires "view"   updating it from pure to view


    //@audit   arithmetic underflow or overflow (0x11)] for basePriceInMatic 10000000000000000 


  //  stat.stat1 =10
 // stat.stat2 = 20
 // statPriceMultiplier__ =  (10+20)*100/2 = 1500 
  
  //10000000000000000* statPriceMultiplier__   10000000000000000*1500
  
 




    
    // function calculatePrice(StatType memory stat)                 // previous code
    //     public
    //     pure
    //     returns (uint256)
    // {
    //     return (BASE_PRICE_IN_MATIC * statPriceMultiplier__(stat));    // 1%*statPriceMultiplier

    // }


     function calculatePrice(StatType memory stat)                 // updated code
        public
        view
        returns (uint256)
    {
        return (BASE_PRICE_IN_MATIC * statPriceMultiplier__(stat));    

    }

///////////////////////////////////////////////////////////////ND////////////////////////////////////////////////////////////////////////////
// @audit power level -> 0 ,1 ,3  // basically it shows value of that asset in marketplace
    function powerLevel__(uint256 tokenId) public view returns (uint256) {
        StatType memory previousStat = upgradeMapping[tokenId];
        return
            ((previousStat.stat1 + baseStat.stat1) +
                (previousStat.stat2 + baseStat.stat2)) / 2;
    }


/////////////////////////////////////////////////////////////////ND//////////////////////////////////////////////////////////////////////////


    function powerLevelColor(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        uint256 powerlevel = powerLevel__(tokenId);
        if (powerlevel == 0) return svgColors[0];
        for (uint256 i; i < colorRanges.length - 1; i++) {
            if (
                powerlevel >= colorRanges[i] && powerlevel < colorRanges[i + 1]
            ) {
                return svgColors[i];
            }
        }
        return svgColors[0];
    }
////////////////////////////////////////////////////////////////////ND///////////////////////////////////////////////////////////////////////
    function statPriceMultiplier__(StatType memory stat)
        public
        pure
        returns (uint256)
    {
        return ((stat.stat1 + stat.stat2) * 100) / 2;  //For considering decimal (denominator averageing out)
    }


//////////////////////////////////////////////////////////////////ND/////////////////////////////////////////////////////////////////////////
    
    //@audit could be made private
    
    function calculateUpgrade(StatType memory previousStat)   
        public
        returns (StatType memory)
    {
        bytes32 hash = _generateStatHash(previousStat);
        StatType memory newStat = newStatMap[hash];
        if (isEmptyStat(newStat)) {
            newStat = calculateStat__(previousStat, 3);
            newStatMap[hash] = newStat;
        }
        return newStat;
    }
/////////////////////////////////////////////////////////////////ND//////////////////////////////////////////////////////////////////////////
    
    function _generateStatHash(StatType memory _stat)
        internal
        pure
        returns (bytes32 hash)
    {
        assembly {
            // Calculate the size of the struct in bytes
            let size := mload(_stat)
            // Point to the memory location of the struct
            let ptr := _stat
            // Compute the hash using Keccak256
            hash := keccak256(ptr, size)
        }
        // return
        //   keccak256(
        //     abi.encode(
        //       _stat.stat1,
        //       _stat.stat2,
        //       _stat.specialType,
        //       _stat.specialPoints
        //     )
        //   );
    }

    ///////////////////////////////////////////////////////////////D/////////////////////////////////////////////////////////////////////


    function calculateStat__(StatType memory previousStat, uint8 _increment)   
        internal
        pure
        returns (StatType memory)
    {
        previousStat.stat1 += _increment;
        previousStat.stat2 += _increment;
        return previousStat;
    }


    ////////////////////////////////////////////////////////////D////////////////////////////////////////////////////////////////////////

    //@audit when no tokenID minted  it should return zero


    function getStat(string memory statLabel, uint256 tokenId)       
        public
        view
        returns (uint8 stat)
    {
        if (stringEqual(statLabel, statLabels[0]))
            return upgradeMapping[tokenId].stat1 + baseStat.stat1;
        else if (stringEqual(statLabel, statLabels[1]))
            return upgradeMapping[tokenId].stat2 + baseStat.stat2;
        else return 0;
    }
//////////////////////////////////////////////////////////////////D///////////////////////////////////////////////////////////////////////
   
    function getSpecial(uint256 tokenId) public view returns (uint8, uint8) {
        return (
            upgradeMapping[tokenId].specialType,
            upgradeMapping[tokenId].specialPoints
        );
    }

////////////////////////////////////////////////////////////////////D/////////////////////////////////////////////////////////////////////

    function isEmptyStat(StatType memory newStat) internal pure returns (bool) {
        return
            newStat.stat1 == 0 &&
            newStat.stat2 == 0 &&
            newStat.specialType == 0 &&
            newStat.specialPoints == 0;
    }
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // CCIP   // @audit -> not using in this code
    // function statToString(StatType memory stat)
    //     internal
    //     pure
    //     returns (string memory)
    // {
    //     bytes memory result = new bytes(4);
    //     result[0] = bytes1(stat.stat1);
    //     result[1] = bytes1(stat.stat2);
    //     result[2] = bytes1(stat.specialType);
    //     result[3] = bytes1(stat.specialPoints);
    //     return string(result);
    // }

/////////////////////////////////////////////////////////////////D/////////////////////////////////////////////////////////////////////
    
    function stringEqual(string memory str1, string memory str2)
        internal
        pure
        returns (bool)
    {
        return
            bytes32(keccak256(abi.encode(str1))) ==
            bytes32(keccak256(abi.encode(str2)));
    }

//////////////////////////////////////////////////////////////////D////////////////////////////////////////////////////////////////////

// @audit why lock check while transferring?


    function transfer(address to, uint256 tokenId) public isUnlocked(tokenId) {
        require(to != address(0), "ERC721: transfer to the zero address");

        _transfer(_msgSender(), to, tokenId);
    }
///////////////////////////////////////////////////////////////////D///////////////////////////////////////////////////////////////////
    
    function getOwner(uint256 tokenId) public view returns (address) {
        return _ownerOf(tokenId);
    }

//////////////////////////////////////////////////////////////////D////////////////////////////////////////////////////////////////////
// @audit why lock check while transferring?

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override isUnlocked(tokenId) {
        require(to != address(0), "ERC721: transfer to the zero address");

        _transfer(from, to, tokenId);
    }
}