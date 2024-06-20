<<<<<<< HEAD
// SPDX-License-Identifier: MIT

//https://docs.chain.link/ccip/tutorials/send-arbitrary-data
pragma solidity ^0.8.24;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./StringUtil.sol";
import "./IRPG.sol";

contract CCIP_RPG_SENDER is CCIPReceiver, OwnerIsCreator {
    using StringUtil for string;
    using Strings for uint256;
    using Strings for uint8;
    using Strings for uint160;
    uint256 private _gasLimit;                               // @audit RPG

    IRPGItemNFT public nftContract;
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees); // Used to make sure contract has enough balance.
    error NothingToWithdraw(); // Used when trying to withdraw Ether but there's nothing to withdraw.
    error FailedToWithdrawEth(address owner, address target, uint256 value); // Used when the withdrawal of Ether fails.
    error DestinationChainNotAllowlisted(uint64 destinationChainSelector); // Used when the destination chain has not been allowlisted by the contract owner.
    error SourceChainNotAllowlisted(uint64 sourceChainSelector); // Used when the source chain has not been allowlisted by the contract owner.
    error SenderNotAllowlisted(address sender); // Used when the sender has not been allowlisted by the contract owner.
    error InvalidReceiverAddress(); // Used when the receiver address is 0.

    event MessageSent(
        bytes32 indexed messageId, // The unique ID of the CCIP message.
        uint64 indexed destinationChainSelector, // The chain selector of the destination chain.
        address receiver, // The address of the receiver on the destination chain.
        string text, // The text being sent.
        address feeToken, // the token address used to pay CCIP fees.
        uint256 fees // The fees paid for sending the CCIP message.
    );

    event MessageReceived(
        bytes32 indexed messageId, // The unique ID of the CCIP message.
        uint64 indexed sourceChainSelector, // The chain selector of the source chain.
        address sender, // The address of the sender from the source chain.
        string text // The text that was received.
    );

    bytes32 private s_lastReceivedMessageId; // Store the last received messageId.
    string private s_lastReceivedText; // Store the last received text.

    mapping(uint64 => bool) public allowlistedDestinationChains;

    mapping(uint64 => bool) public allowlistedSourceChains;

    mapping(address => bool) public allowlistedSenders;

    constructor(address _router, uint256 gasLimit) CCIPReceiver(_router) {
        _gasLimit = gasLimit;                                                      // @audit RPG why gaslimit //  gaslimit : 800000
    }

    modifier onlyAllowlistedDestinationChain(uint64 _destinationChainSelector) {
        if (!allowlistedDestinationChains[_destinationChainSelector])
            revert DestinationChainNotAllowlisted(_destinationChainSelector);
        _;
    }
    modifier onlyAllowlisted(uint64 _sourceChainSelector, address _sender) {
        if (!allowlistedSourceChains[_sourceChainSelector])
            revert SourceChainNotAllowlisted(_sourceChainSelector);
        if (!allowlistedSenders[_sender]) revert SenderNotAllowlisted(_sender);
        _;
    }

    modifier validateReceiver(address _receiver) {
        if (_receiver == address(0)) revert InvalidReceiverAddress();
        _;
    }

    function getHash(address contractAddress) // used to generate the hash of given contract will used in verification that it is depolyed by us
        public
        view
        returns (string memory)
    {
        return uint256(keccak256(address(contractAddress).code)).toString();
    }

    function getMultipleHash(address[] calldata contractAddresses) view public returns (string[] memory){
        string[] memory hashArray = new string[](contractAddresses.length);
        for (uint256 i; i<contractAddresses.length; i++){
            hashArray[i] = getHash(contractAddresses[i]);
        }
        return hashArray;
    }
    

    function allowlistDestinationChain(
        uint64 _destinationChainSelector,
        bool allowed
    ) external onlyOwner {
        allowlistedDestinationChains[_destinationChainSelector] = allowed;
    }

    function allowlistSourceChain(uint64 _sourceChainSelector, bool allowed)
        external
        onlyOwner
    {
        allowlistedSourceChains[_sourceChainSelector] = allowed;
    }

    function allowlistSender(address _sender, bool allowed) external onlyOwner {
        allowlistedSenders[_sender] = allowed;
    }

    function setGasLimit(uint256 _limit) external onlyOwner {                //@audit RPG
        _gasLimit = _limit;
    }

    function asciiToUint(string memory _asciiString)                         //@audit RPG   // because in ccip we can only send strings this is for tha purpose // @audit can be made internal
        public
        pure
        returns (uint256)
    {
        uint256 result = 0;
        bytes memory stringAsBytes = bytes(_asciiString);

        for (uint256 i = 0; i < stringAsBytes.length; i++) {
            // Convert each character to its ASCII value
            uint8 asciiValue = uint8(stringAsBytes[i]);
            result = result * 10 + (asciiValue - 48); 
        }
        return result;
    }

    function uintToASCII(uint256 _number) public pure returns (string memory) {     //@audit RPG
        return _number.toString();
    }

    function addressToString(address _address)                                     //@audit RPG
        public
        pure
        returns (string memory)
    {
        return uint160(_address).toString();
    }

    function stringToAddress(string memory _string)                   //@audit RPG
        public
        pure
        returns (address)
    {
        uint256 number = asciiToUint(_string);
        require(number < type(uint160).max, "Invalid address");
        return address(uint160(number));
    }

    function createMessageStr(                   // @audit @dev RPG    // here we craft stats in this chain (construct) and destruct it later on different chain
        uint256 tokenId,
        address nftOwner,
        address senderContractAdd,
        address receiverContractAdd,
        string memory msgType,
        uint8[] memory stats
    ) public pure returns (string memory) {
        require(
            stats.length == 4,
            "Stats array must contain exactly four elements"
        );
        return
            string(                                     // @audit @dev RPG
                abi.encodePacked(
                    tokenId.toString(),
                    ":",
                    addressToString(nftOwner),
                    ":",
                    msgType,
                    ":",
                    addressToString(senderContractAdd),
                    ":",
                    addressToString(receiverContractAdd),
                    ":",
                    stats[0].toString(),
                    ":",
                    stats[1].toString(),
                    ":",
                    stats[2].toString(),
                    ":",
                    stats[3].toString(),
                    ":"
                )
            );
    }

    function readMessageStr(string memory _str)     // @audit @dev RPG deconstuct message on desitnation chain
        public
        pure
        returns (string[] memory messageParts)
    {
        messageParts = _str.split(":");
    }

    function transferNft(                              //@audit RPG were you able to transfer nft?
        uint256 _tokenId,
        address senderNftContractAddress,
        address destinationNftContractAddress,
        uint64 destinationChainId,
        address _receiver //ccip receiver opposite chain
    ) public payable {
        nftContract = IRPGItemNFT(senderNftContractAddress);
        address nftOwner = nftContract.getOwner(_tokenId);
        require(nftOwner != address(0), "Token does not exist");
        require(
            nftContract.isApprovedForAll(nftOwner, address(this)),
            "Token is not approved for transfer"
        );

        require(
            !nftContract.lockStatus(_tokenId),                    //@audit purpose of locking?
            "Token is locked and cannot be transferred"
        );

        // Get the stats of the token
        (uint8 stat1, uint8 stat2, uint8 specialType, uint8 specialPoints) = nftContract
            .getTokenStats(_tokenId);

        // Create an array of stats
        uint8[] memory stats = new uint8[](4);
        stats[0] = stat1;
        stats[1] = stat2;
        stats[2] = specialType;
        stats[3] = specialPoints;

        string memory message = createMessageStr(
            _tokenId,
            nftOwner,
            senderNftContractAddress,
            destinationNftContractAddress,
            "TRANSFER",
            stats
        );

        uint256 unlockTime = block.timestamp + 2 hours;
        nftContract.setTokenLockStatus(_tokenId, unlockTime);
        this.sendMessage{value: msg.value}(
            destinationChainId,
            _receiver,
            message
        );
    }

    function getFeeNative(
        uint64 destinationChainSelector,
        address receiver,
        string calldata _text
    ) public view returns (uint256 fees) {
        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
            receiver,
            _text,
            address(0),
            _gasLimit
        );

        IRouterClient router = IRouterClient(this.getRouter());
        fees = router.getFee(destinationChainSelector, evm2AnyMessage);
    }
    // Fees from contract 
    function sendAcknowledgement(
        uint64 _destinationChainSelector,
        address _receiver,
        string memory _text
    )
        public
        onlyAllowlistedDestinationChain(_destinationChainSelector)
        validateReceiver(_receiver)
        returns (bytes32 messageId)
    {
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver), 
            data: abi.encode(_text),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: _gasLimit})
            ),
            feeToken: address(0)
        });

        IRouterClient router = IRouterClient(this.getRouter());

        uint256 fees = router.getFee(_destinationChainSelector, evm2AnyMessage);

        if (fees > address(this).balance)
            revert NotEnoughBalance(address(this).balance, fees);

        messageId = router.ccipSend{value: fees}(
            _destinationChainSelector,
            evm2AnyMessage
        );

        emit MessageSent(
            messageId,
            _destinationChainSelector,
            _receiver,
            _text,
            address(0),
            fees
        );

        return messageId;
    }

    // fees from user
    function sendMessage(
        uint64 _destinationChainSelector,
        address _receiver,
        string calldata _text
    )
        external
        payable
        onlyAllowlistedDestinationChain(_destinationChainSelector)
        validateReceiver(_receiver)
        returns (bytes32 messageId)
    {
        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
            _receiver,
            _text,
            address(0),
            _gasLimit
        );

        IRouterClient router = IRouterClient(this.getRouter());

        uint256 fees = router.getFee(_destinationChainSelector, evm2AnyMessage);

        if (fees > msg.value) revert NotEnoughBalance(msg.value, fees);
        messageId = router.ccipSend{value: fees}(
            _destinationChainSelector,
            evm2AnyMessage
        );
    }

 // @audit //@dev
    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage)
        internal
        override
        onlyAllowlisted(
            any2EvmMessage.sourceChainSelector,
            abi.decode(any2EvmMessage.sender, (address))
        )
    {
        s_lastReceivedMessageId = any2EvmMessage.messageId;
        s_lastReceivedText = abi.decode(any2EvmMessage.data, (string));
        string[] memory messageParts = readMessageStr(s_lastReceivedText);
        uint256 tokenId = asciiToUint(messageParts[0]);
        address newOwner = stringToAddress(messageParts[1]);

        if (StringUtil.compareTo(messageParts[2], "TRANSFER")) {
            IRPGItemNFT rpgContract = IRPGItemNFT(
                stringToAddress(messageParts[4])
            );
            if (rpgContract.lockStatus(tokenId)) {
                rpgContract.setTokenLockStatus(tokenId, 0);
            }
            uint8 stat1 = uint8(asciiToUint(messageParts[5]));
            uint8 stat2 = uint8(asciiToUint(messageParts[6]));
            uint8 specialType = uint8(asciiToUint(messageParts[7]));
            uint8 specialPoints = uint8(asciiToUint(messageParts[8]));

            if (
                rpgContract.getOwner(tokenId) != address(0) &&
                rpgContract.getOwner(tokenId) != newOwner
            ) {
                rpgContract.transferFrom(
                    rpgContract.getOwner(tokenId),
                    newOwner,
                    tokenId
                );
            }
            // rpgContract.updateStatsAndUser(
            //     tokenId,
            //     newOwner,
            //     stat1,
            //     stat2,
            //     stat3,
            //     stat4
            // );


               rpgContract.updateStats(
                tokenId,
                newOwner,
                stat1,
                stat2,
                specialType,
                specialPoints
            );

            string memory message = createMessageStr(
                tokenId,
                newOwner,
                stringToAddress(messageParts[3]),
                stringToAddress(messageParts[4]),
                "ACK",
                new uint8[](4)
            );
            this.sendAcknowledgement(
                any2EvmMessage.sourceChainSelector,
                abi.decode(any2EvmMessage.sender, (address)),
                message
            );
        } else if (StringUtil.compareTo(messageParts[2], "ACK")) {
            IRPGItemNFT rpgContract = IRPGItemNFT(
                stringToAddress(messageParts[3])
            );
            uint256 _tokenId = asciiToUint(messageParts[0]);
            uint256 unlockTime = type(uint256).max;
            rpgContract.setTokenLockStatus(_tokenId, unlockTime);
        } else {
            revert("Unknown message type");
        }

        emit MessageReceived(
            any2EvmMessage.messageId,
            any2EvmMessage.sourceChainSelector,
            abi.decode(any2EvmMessage.sender, (address)),
            abi.decode(any2EvmMessage.data, (string))
        );
    }

    function _buildCCIPMessage(
        address _receiver,
        string calldata _text,
        address _feeTokenAddress,
        uint gasLimit
    ) private pure returns (Client.EVM2AnyMessage memory) {
        return
            Client.EVM2AnyMessage({
                receiver: abi.encode(_receiver),
                data: abi.encode(_text),
                tokenAmounts: new Client.EVMTokenAmount[](0),
                extraArgs: Client._argsToBytes(
                    Client.EVMExtraArgsV1({gasLimit: gasLimit})
                ),
                feeToken: _feeTokenAddress
            });
    }

    function getLastReceivedMessageDetails()
        external
        view
        returns (bytes32 messageId, string memory text)
    {
        return (s_lastReceivedMessageId, s_lastReceivedText);
    }

    receive() external payable {}

    function withdraw(address _beneficiary) public onlyOwner {
        uint256 amount = address(this).balance;

        if (amount == 0) revert NothingToWithdraw();
        (bool sent, ) = _beneficiary.call{value: amount}("");

        if (!sent) revert FailedToWithdrawEth(msg.sender, _beneficiary, amount);
    }

    function withdrawToken(address _beneficiary, address _token)
        public
        onlyOwner
    {
        // Retrieve the balance of this contract
        uint256 amount = IERC20(_token).balanceOf(address(this));

        // Revert if there is nothing to withdraw
        if (amount == 0) revert NothingToWithdraw();

        IERC20(_token).transfer(_beneficiary, amount);
    }
}
=======
// SPDX-License-Identifier: MIT

//https://docs.chain.link/ccip/tutorials/send-arbitrary-data
pragma solidity ^0.8.24;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./StringUtil.sol";
import "./IRPG.sol";

contract CCIP_RPG_SENDER is CCIPReceiver, OwnerIsCreator {
    using StringUtil for string;
    using Strings for uint256;
    using Strings for uint8;
    using Strings for uint160;
    uint256 private _gasLimit;                               // @audit RPG
    IRPGItemNFT public nftContract;
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees); // Used to make sure contract has enough balance.
    error NothingToWithdraw(); // Used when trying to withdraw Ether but there's nothing to withdraw.
    error FailedToWithdrawEth(address owner, address target, uint256 value); // Used when the withdrawal of Ether fails.
    error DestinationChainNotAllowlisted(uint64 destinationChainSelector); // Used when the destination chain has not been allowlisted by the contract owner.
    error SourceChainNotAllowlisted(uint64 sourceChainSelector); // Used when the source chain has not been allowlisted by the contract owner.
    error SenderNotAllowlisted(address sender); // Used when the sender has not been allowlisted by the contract owner.
    error InvalidReceiverAddress(); // Used when the receiver address is 0.

    event MessageSent(
        bytes32 indexed messageId, // The unique ID of the CCIP message.
        uint64 indexed destinationChainSelector, // The chain selector of the destination chain.
        address receiver, // The address of the receiver on the destination chain.
        string text, // The text being sent.
        address feeToken, // the token address used to pay CCIP fees.
        uint256 fees // The fees paid for sending the CCIP message.
    );

    event MessageReceived(
        bytes32 indexed messageId, // The unique ID of the CCIP message.
        uint64 indexed sourceChainSelector, // The chain selector of the source chain.
        address sender, // The address of the sender from the source chain.
        string text // The text that was received.
    );

    bytes32 private s_lastReceivedMessageId; // Store the last received messageId.
    string private s_lastReceivedText; // Store the last received text.

    mapping(uint64 => bool) public allowlistedDestinationChains;

    mapping(uint64 => bool) public allowlistedSourceChains;

    mapping(address => bool) public allowlistedSenders;

    constructor(address _router, uint256 gasLimit) CCIPReceiver(_router) {
        _gasLimit = gasLimit;                                                      // @audit RPG why gaslimit //  gaslimit : 800000
    }

    modifier onlyAllowlistedDestinationChain(uint64 _destinationChainSelector) {
        if (!allowlistedDestinationChains[_destinationChainSelector])
            revert DestinationChainNotAllowlisted(_destinationChainSelector);
        _;
    }
    modifier onlyAllowlisted(uint64 _sourceChainSelector, address _sender) {
        if (!allowlistedSourceChains[_sourceChainSelector])
            revert SourceChainNotAllowlisted(_sourceChainSelector);
        if (!allowlistedSenders[_sender]) revert SenderNotAllowlisted(_sender);
        _;
    }

    modifier validateReceiver(address _receiver) {
        if (_receiver == address(0)) revert InvalidReceiverAddress();
        _;
    }

    function allowlistDestinationChain(
        uint64 _destinationChainSelector,
        bool allowed
    ) external onlyOwner {
        allowlistedDestinationChains[_destinationChainSelector] = allowed;
    }

    function allowlistSourceChain(uint64 _sourceChainSelector, bool allowed)
        external
        onlyOwner
    {
        allowlistedSourceChains[_sourceChainSelector] = allowed;
    }

    function allowlistSender(address _sender, bool allowed) external onlyOwner {
        allowlistedSenders[_sender] = allowed;
    }

    function setGasLimit(uint256 _limit) external onlyOwner {                //@audit RPG
        _gasLimit = _limit;
    }

    function asciiToUint(string memory _asciiString)                         //@audit RPG   // because in ccip we can only send strings this is for tha purpose // @audit can be made internal
        public
        pure
        returns (uint256)
    {
        uint256 result = 0;
        bytes memory stringAsBytes = bytes(_asciiString);

        for (uint256 i = 0; i < stringAsBytes.length; i++) {
            // Convert each character to its ASCII value
            uint8 asciiValue = uint8(stringAsBytes[i]);
            result = result * 10 + (asciiValue - 48); 
        }
        return result;
    }

    function uintToASCII(uint256 _number) public pure returns (string memory) {     //@audit RPG
        return _number.toString();
    }

    function addressToString(address _address)                                     //@audit RPG
        public
        pure
        returns (string memory)
    {
        return uint160(_address).toString();
    }

    function stringToAddress(string memory _string)                   //@audit RPG
        public
        pure
        returns (address)
    {
        uint256 number = asciiToUint(_string);
        require(number < type(uint160).max, "Invalid address");
        return address(uint160(number));
    }

    function createMessageStr(                   // @audit @dev RPG    // here we craft stats in this chain (construct) and destruct it later on different chain
        uint256 tokenId,
        address nftOwner,
        address senderContractAdd,
        address receiverContractAdd,
        string memory msgType,
        uint8[] memory stats
    ) public pure returns (string memory) {
        require(
            stats.length == 4,
            "Stats array must contain exactly four elements"
        );
        return
            string(                                     // @audit @dev RPG
                abi.encodePacked(
                    tokenId.toString(),
                    ":",
                    addressToString(nftOwner),
                    ":",
                    msgType,
                    ":",
                    addressToString(senderContractAdd),
                    ":",
                    addressToString(receiverContractAdd),
                    ":",
                    stats[0].toString(),
                    ":",
                    stats[1].toString(),
                    ":",
                    stats[2].toString(),
                    ":",
                    stats[3].toString(),
                    ":"
                )
            );
    }

    function readMessageStr(string memory _str)     // @audit @dev RPG deconstuct message on desitnation chain
        public
        pure
        returns (string[] memory messageParts)
    {
        messageParts = _str.split(":");
    }

    function transferNft(                              //@audit RPG were you able to transfer nft?
        uint256 _tokenId,
        address senderNftContractAddress,
        address destinationNftContractAddress,
        uint64 destinationChainId,
        address _receiver //ccip receiver opposite chain
    ) public payable {
        nftContract = IRPGItemNFT(senderNftContractAddress);
        address nftOwner = nftContract.getOwner(_tokenId);
        require(nftOwner != address(0), "Token does not exist");
        require(
            nftContract.isApprovedForAll(nftOwner, address(this)),
            "Token is not approved for transfer"
        );

        require(
            !nftContract.lockStatus(_tokenId),                    //@audit purpose of locking?
            "Token is locked and cannot be transferred"
        );

        // Get the stats of the token
        (uint8 stat1, uint8 stat2, uint8 stat3, uint8 stat4) = nftContract
            .getTokenStats(_tokenId);

        // Create an array of stats
        uint8[] memory stats = new uint8[](4);
        stats[0] = stat1;
        stats[1] = stat2;
        stats[2] = stat3;
        stats[3] = stat4;

        string memory message = createMessageStr(
            _tokenId,
            nftOwner,
            senderNftContractAddress,
            destinationNftContractAddress,
            "TRANSFER",
            stats
        );

        uint256 unlockTime = block.timestamp + 2 hours;
        nftContract.setTokenLockStatus(_tokenId, unlockTime);
        this.sendMessage{value: msg.value}(
            destinationChainId,
            _receiver,
            message
        );
    }

    function getFeeNative(
        uint64 destinationChainSelector,
        address receiver,
        string calldata _text
    ) public view returns (uint256 fees) {
        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
            receiver,
            _text,
            address(0),
            _gasLimit
        );

        IRouterClient router = IRouterClient(this.getRouter());
        fees = router.getFee(destinationChainSelector, evm2AnyMessage);
    }
    // Fees from contract 
    function sendAcknowledgement(
        uint64 _destinationChainSelector,
        address _receiver,
        string memory _text
    )
        public
        onlyAllowlistedDestinationChain(_destinationChainSelector)
        validateReceiver(_receiver)
        returns (bytes32 messageId)
    {
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver), 
            data: abi.encode(_text),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: _gasLimit})
            ),
            feeToken: address(0)
        });

        IRouterClient router = IRouterClient(this.getRouter());

        uint256 fees = router.getFee(_destinationChainSelector, evm2AnyMessage);

        if (fees > address(this).balance)
            revert NotEnoughBalance(address(this).balance, fees);

        messageId = router.ccipSend{value: fees}(
            _destinationChainSelector,
            evm2AnyMessage
        );

        emit MessageSent(
            messageId,
            _destinationChainSelector,
            _receiver,
            _text,
            address(0),
            fees
        );

        return messageId;
    }

    // fees from user
    function sendMessage(
        uint64 _destinationChainSelector,
        address _receiver,
        string calldata _text
    )
        external
        payable
        onlyAllowlistedDestinationChain(_destinationChainSelector)
        validateReceiver(_receiver)
        returns (bytes32 messageId)
    {
        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
            _receiver,
            _text,
            address(0),
            _gasLimit
        );

        IRouterClient router = IRouterClient(this.getRouter());

        uint256 fees = router.getFee(_destinationChainSelector, evm2AnyMessage);

        if (fees > msg.value) revert NotEnoughBalance(msg.value, fees);
        messageId = router.ccipSend{value: fees}(
            _destinationChainSelector,
            evm2AnyMessage
        );
    }

 // @audit //@dev
    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage)
        internal
        override
        onlyAllowlisted(
            any2EvmMessage.sourceChainSelector,
            abi.decode(any2EvmMessage.sender, (address))
        )
    {
        s_lastReceivedMessageId = any2EvmMessage.messageId;
        s_lastReceivedText = abi.decode(any2EvmMessage.data, (string));
        string[] memory messageParts = readMessageStr(s_lastReceivedText);
        uint256 tokenId = asciiToUint(messageParts[0]);
        address newOwner = stringToAddress(messageParts[1]);

        if (StringUtil.compareTo(messageParts[2], "TRANSFER")) {
            IRPGItemNFT rpgContract = IRPGItemNFT(
                stringToAddress(messageParts[4])
            );
            if (rpgContract.lockStatus(tokenId)) {
                rpgContract.setTokenLockStatus(tokenId, 0);
            }
            uint8 stat1 = uint8(asciiToUint(messageParts[5]));
            uint8 stat2 = uint8(asciiToUint(messageParts[6]));
            uint8 stat3 = uint8(asciiToUint(messageParts[7]));
            uint8 stat4 = uint8(asciiToUint(messageParts[8]));

            if (
                rpgContract.getOwner(tokenId) != address(0) &&
                rpgContract.getOwner(tokenId) != newOwner
            ) {
                rpgContract.transferFrom(
                    rpgContract.getOwner(tokenId),
                    newOwner,
                    tokenId
                );
            }
            rpgContract.updateStatsAndUser(
                tokenId,
                newOwner,
                stat1,
                stat2,
                stat3,
                stat4
            );

            string memory message = createMessageStr(
                tokenId,
                newOwner,
                stringToAddress(messageParts[3]),
                stringToAddress(messageParts[4]),
                "ACK",
                new uint8[](4)
            );
            this.sendAcknowledgement(
                any2EvmMessage.sourceChainSelector,
                abi.decode(any2EvmMessage.sender, (address)),
                message
            );
        } else if (StringUtil.compareTo(messageParts[2], "ACK")) {
            IRPGItemNFT rpgContract = IRPGItemNFT(
                stringToAddress(messageParts[3])
            );
            uint256 _tokenId = asciiToUint(messageParts[0]);
            uint256 unlockTime = type(uint256).max;
            rpgContract.setTokenLockStatus(_tokenId, unlockTime);
        } else {
            revert("Unknown message type");
        }

        emit MessageReceived(
            any2EvmMessage.messageId,
            any2EvmMessage.sourceChainSelector,
            abi.decode(any2EvmMessage.sender, (address)),
            abi.decode(any2EvmMessage.data, (string))
        );
    }

    function _buildCCIPMessage(
        address _receiver,
        string calldata _text,
        address _feeTokenAddress,
        uint gasLimit
    ) private pure returns (Client.EVM2AnyMessage memory) {
        return
            Client.EVM2AnyMessage({
                receiver: abi.encode(_receiver),
                data: abi.encode(_text),
                tokenAmounts: new Client.EVMTokenAmount[](0),
                extraArgs: Client._argsToBytes(
                    Client.EVMExtraArgsV1({gasLimit: gasLimit})
                ),
                feeToken: _feeTokenAddress
            });
    }

    function getLastReceivedMessageDetails()
        external
        view
        returns (bytes32 messageId, string memory text)
    {
        return (s_lastReceivedMessageId, s_lastReceivedText);
    }

    receive() external payable {}

    function withdraw(address _beneficiary) public onlyOwner {
        uint256 amount = address(this).balance;

        if (amount == 0) revert NothingToWithdraw();
        (bool sent, ) = _beneficiary.call{value: amount}("");

        if (!sent) revert FailedToWithdrawEth(msg.sender, _beneficiary, amount);
    }

    function withdrawToken(address _beneficiary, address _token)
        public
        onlyOwner
    {
        // Retrieve the balance of this contract
        uint256 amount = IERC20(_token).balanceOf(address(this));

        // Revert if there is nothing to withdraw
        if (amount == 0) revert NothingToWithdraw();

        IERC20(_token).transfer(_beneficiary, amount);
    }
}

>>>>>>> 0265555e7aada10d69597a73957dce49be29f450
