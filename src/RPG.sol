//   * can transfer the NFT
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./RPGItemUtils.sol";

//@dev trailing __ in var names means they will be hardcoded when contract is generated and depolyed by us

contract RPGItemNFT is ERC721, Ownable, RPGItemUtils {
    using Strings for uint256;

    uint8[] private colorRanges;
    uint256 public mintPrice;
    uint256 private _nextTokenId;
    uint256 public constant BASE_PRICE_IN_MATIC = 1e18 / 100; // 1 % of 1 ether @dev made it constant but public
    uint256 private _parentChainId;
    string[2] public statLabels;
    string[] private svgColors;
    string public itemType;
    string public _sign; //@dev sign is signature look at setter fun for more info purpose //@auditV2 : temprory updating to public for test purpose
    string public itemImage__ =
        "https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/Bitcoin_logo.jpg/640px-Bitcoin_logo.jpg";
    string public lockedItemImage =
        "https://plum-liable-mastodon-450.mypinata.cloud/ipfs/QmaXD4NLN9hn5cb9jTd78faMvU3RNmf34gvhLGsnq67zs3";
    address public _ccipHandler; //@audit : made it public for testing purpose ,also better to make it public anyways to validate via UX

    StatType baseStat;

    mapping(uint256 => StatType) public upgradeMapping; // tokenID->StatType  // @audit made it public for testing purpose
    mapping(uint256 => uint256) public tokenLockedTill; // ccip related // tokenID -> unlockTime //@audit should be make public to validate via UX how much time left //also made public for testing purpose
    // @dev cur stat to hash and store the value of updraged stat
    // @dev to reduce computation in contract eg if A goes from 1->2 it is not required for user B to compute the stat upgradation again
    mapping(bytes32 => StatType) public newStatMap; // hash of StatType -> StatType   // @audit made it public for testing purpose

    //////------events-----//////////////////////////////////////////////////////D//////////////////////////////////////////////////////////////////////////////
    event NftMinted(address indexed recipient, uint256 indexed tokenId, uint256 indexed timestamp);
    event Transfer(address indexed sender, uint256 indexed amount);

    /////------MODIFIERS---///////////////////////////////////////////////////////D//////////////////////////////////////////////////////////////////////////////

    modifier onlyCCIPRouter() {
        require(msg.sender == _ccipHandler, "Caller is not the CCIP router");
        _;
    }

    modifier isUnlocked(uint256 tokenId) {
        require(tokenLockedTill[tokenId] <= block.timestamp, "Token is locked");
        _;
    }

    modifier isTokenMinted(uint256 tokenId) {
        require(_ownerOf(tokenId) != address(0), "Token is not Minted");
        _;
    }

    constructor()
        ERC721("Sword", "SW")
        Ownable(0xB1293a8BFf9323AaD0419e46dd9846cC7363d44B) //@auditV2 :is cciphandler contract is owner of rpg contract??seems incorrect
    {
        baseStat.stat1 = 10;
        baseStat.stat2 = 20;
        baseStat.specialType = 30;
        baseStat.specialPoints = 40;
        statLabels = ["l1", "l2"];
        itemType = "weapon";
        svgColors = ["#f2f2f2", "#2f2f2f", "#dedede"];
        colorRanges = [0, 10, 20, 30];
        _ccipHandler = 0xa1293A8bFf9323aAd0419E46Dd9846Cc7363D44b;
        mintPrice = 10000000000000000;
        _parentChainId = 1;
    }

    receive() external payable {
        emit Transfer(msg.sender, msg.value);
    }

    function lockStatus(uint256 tokenId) public view returns (bool) {
        //@auditV2: only via trnsferring the NFT
        return (tokenLockedTill[tokenId] > block.timestamp); //@auditV2 :when token is just minted by rpg contract,what would be its lock status ->by this logic it should be false
    }

    function setTokenLockStatus( //@auditV2 : how much unlocktime is getting set by ccipRouter
        uint256 tokenId,
        uint256 unlockTime //CCIP use
    ) public onlyCCIPRouter {
        tokenLockedTill[tokenId] = unlockTime;
    }

    function setSign(string memory sign) external {
        //@auditV2 : should be onlyOwner
        // This function sets the signature used to verify that the NFT was minted by Game-X.
        // Once the contract is deployed, this signature is set and is used for cross-verification.
        // When checking the minted NFT, this signature is compared against the signature stored in the NFT metadata
        // to ensure authenticity and confirm that it was minted by our Game-X software.
        _sign = sign;
    }

    function changeCCIP(address newAdd) external onlyOwner {
        // @dev added modifier
        _ccipHandler = newAdd;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        //@dev added modifier
        require(_mintPrice >= 0, "invalid price"); //@auditV2 : should be >0 (if zero selling it for free?) ,otherwise we do not require this require statement,anyways it will only take upto unit256.max as a param
        mintPrice = _mintPrice;
    }

    //@dev used in ccip to get NFT stats that are sended ;  #ccip related
    //@dev it is working fine now
    function getTokenStats(
        uint256 tokenId //@audit what is the purpose of this,confusion with getStats()
    ) public view isTokenMinted(tokenId) returns (uint8, uint8, uint8, uint8) {
        //@auditV2 : if it is ccip related then only ccipRouter should be able to call this
        StatType memory stats = upgradeMapping[tokenId];
        return (
            stats.stat1 + baseStat.stat1,
            stats.stat2 + baseStat.stat2,
            stats.specialType + baseStat.specialType,
            stats.specialPoints + baseStat.specialPoints
        );
    }

    /////////////////////////////////////////////////////////////////////D///////////////////////////////////////////////////////////////////////

    // @audit : function updateStats() -> anyone who knows the token id would be able to update the stats of the token ,not desirable
    // @dev added modifier so only ccip handler can use this now

    function updateStats(     //@auditV2 : why updatestats are only related to cciprouter?can asset owner not update the stats sitting on single chain and withhout using ccip??
        //ccip related
        uint256 tokenId,
        address newOwner,
        uint8 stat1,
        uint8 stat2,
        uint8 specialType,
        uint8 specialPoints
    ) external onlyCCIPRouter returns (bool) {
        require(newOwner != address(0), "Invalid new owner");
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

    function mint() public payable {
        // @audit //@dev this is required to maintain chain and sync all the chain nfts  //@auditV2 :commenting the chain id require check for test purpose..uncomment it later
        // require(
        //     _parentChainId == block.chainid,
        //     string(abi.encodePacked("Mint not allowed, You can mint on ChainId : ", _parentChainId.toString()))
        // );
        require(msg.value == mintPrice, "Insufficient Ether");
        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
        tokenLockedTill[tokenId] = 0;
        emit NftMinted(msg.sender, tokenId, block.timestamp);
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _ownerOf(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) isTokenMinted(tokenId) returns (string memory) {
        bool tokenLockStatus = lockStatus(tokenId);
        string memory imgSVG = generateSVG(
            tokenLockStatus ? "#808080" : powerLevelColor(tokenId),
            tokenLockStatus ? "??" : Strings.toString(getStat(statLabels[0], tokenId)),
            tokenLockStatus ? "??" : Strings.toString(getStat(statLabels[1], tokenId)),
            tokenLockStatus ? "??" : Strings.toString(powerLevel__(tokenId)),
            tokenLockStatus ? lockedItemImage : itemImage__,
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

        string memory finalTokenURI = string(abi.encodePacked("data:application/json;base64,", json));
        return finalTokenURI;
    }

    function upgrade(uint256 tokenId) public payable isTokenMinted(tokenId) isUnlocked(tokenId) {
        StatType memory previousStat = upgradeMapping[tokenId];
        StatType memory newStat = calculateUpgrade(previousStat);
        require(msg.value >= calculatePrice(newStat), "insufficient fund for upgrade");
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

    function calculatePrice(
        StatType memory stat // @dev updated working
    ) private pure returns (uint256) {
        return ((BASE_PRICE_IN_MATIC) * statPriceMultiplier__(stat)) / 100;
    }

    // @audit power level -> 0 ,1 ,3  // basically it shows value of that asset in marketplace
    function powerLevel__(uint256 tokenId) public view returns (uint256) {
        //@auditV2 : making it public temporarilty for testing purpose
        StatType memory previousStat = upgradeMapping[tokenId];
        return ((previousStat.stat1 + baseStat.stat1) + (previousStat.stat2 + baseStat.stat2)) / 2;
    }

    function powerLevelColor(uint256 tokenId) private view returns (string memory) {
        uint256 powerlevel = powerLevel__(tokenId);
        if (powerlevel == 0) return svgColors[0];
        for (uint256 i; i < colorRanges.length - 1; i++) {
            if (powerlevel >= colorRanges[i] && powerlevel < colorRanges[i + 1]) {
                return svgColors[i];
            }
        }
        return svgColors[0];
    }

    function statPriceMultiplier__(StatType memory stat) private pure returns (uint256) {
        return ((uint256(stat.stat1) + uint256(stat.stat2)) * 100) / 2; //For considering decimal (denominator averageing out)
    }

    //@audit could be made private
    //@dev done
    function calculateUpgrade(StatType memory previousStat) public returns (StatType memory) {
        bytes32 hash = _generateStatHash(previousStat);
        StatType memory newStat = newStatMap[hash];
        if (isEmptyStat(newStat)) {
            newStat = calculateStat__(previousStat, 3);
            newStatMap[hash] = newStat;
        }
        return newStat;
    }

    function calculateStat__(StatType memory previousStat, uint8 _increment) private pure returns (StatType memory) {
        previousStat.stat1 += _increment;
        previousStat.stat2 += _increment;
        if (previousStat.stat1 > 100) {
            previousStat.stat1 = 100;
        }
        if (previousStat.stat2 > 100) {
            previousStat.stat2 = 100;
        }

        return previousStat;
    }

    ////////////////////////////////////////////////////////////D////////////////////////////////////////////////////////////////////////

    //@audit when no tokenID minted  it should return zero
    // @dev it will work for user defined stat only i.e first 2
    function getStat(string memory statLabel, uint256 tokenId)
        public
        view
        isTokenMinted(tokenId)
        isUnlocked(tokenId)
        returns (uint8 stat)
    {
        if (stringEqual(statLabel, statLabels[0])) {
            return upgradeMapping[tokenId].stat1 + baseStat.stat1;
        } else if (stringEqual(statLabel, statLabels[1])) {
            return upgradeMapping[tokenId].stat2 + baseStat.stat2;
        } else {
            return 0;
        }
    }

    //////////////////////////////////////////////////////////////////D///////////////////////////////////////////////////////////////////////
    function getSpecial(uint256 tokenId)
        public
        view
        isTokenMinted(tokenId)
        isUnlocked(tokenId)
        returns (uint8, uint8)
    {
        return (upgradeMapping[tokenId].specialType, upgradeMapping[tokenId].specialPoints);
    }

    ////////////////////////////////////////////////////////////////////D/////////////////////////////////////////////////////////////////////

    function isEmptyStat(StatType memory newStat) private pure returns (bool) {
        return newStat.stat1 == 0 && newStat.stat2 == 0 && newStat.specialType == 0 && newStat.specialPoints == 0;
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

    // @audit why lock check while transferring?
    // @dev coz ccip we need to see if it is locked then nft is on other chain so nft can't be transfer
    //@dev added new modifier
    function transfer(address to, uint256 tokenId) public isTokenMinted(tokenId) isUnlocked(tokenId) {
        require(to != address(0), "ERC721: transfer to the zero address");
        _transfer(_msgSender(), to, tokenId);
    }

    function getOwner(uint256 tokenId) public view returns (address) {
        return _ownerOf(tokenId);
    }

    // @audit why lock check while transferring?
    // @dev coz ccip we need to see if it is locked then nft is on other chain so nft can't be transfer
    //@dev added new modifier
    function transferFrom( //@auditV2: ccip related
    address from, address to, uint256 tokenId)
        public
        override
        onlyCCIPRouter
    {
        require(to != address(0), "ERC721: transfer to the zero address");
        _transfer(from, to, tokenId);
    }
}
