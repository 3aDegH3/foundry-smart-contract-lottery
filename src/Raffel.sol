// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions
// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A sample Raffel contract
 * @author Mohammad Sadeq Jafari
 * @notice This contract is for creating a sample raffel
 * @dev Implements Chainlink VRFv2.5
 */

contract Raffel is VRFConsumerBaseV2Plus {
    /**  Errors */
    error Raffle__UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState
    );
    error Raffel__SendMoreToEnterRaffel();
    error Raffel__TransferFailed();
    error Raffel__RaffelNotOpen();

    /**Type declarations */
    enum RaffelState {
        OPEN,
        CALCULATING
    }

    /** State variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_enteranceFee;
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint256 private s_lastTimeStamp;
    address payable[] private s_players;
    address payable private s_recentWinner;
    RaffelState private s_raffelState;

    /** Events */
    event RaffelEnter(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 enteranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_enteranceFee = enteranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;

        i_callbackGasLimit = callbackGasLimit;
        s_raffelState = RaffelState.OPEN;
    }

    function enterRaffel() external payable {
        if (msg.value < i_enteranceFee) {
            revert Raffel__SendMoreToEnterRaffel();
        }
        if (s_raffelState != RaffelState.OPEN) {
            revert Raffel__RaffelNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit RaffelEnter(msg.sender);
    }
    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. Implicity, your subscription is funded with LINK.
     */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timePasse = (block.timestamp - s_lastTimeStamp >= i_interval);
        bool isOpne = s_raffelState == RaffelState.OPEN;
        bool hashBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = timePasse && isOpne && hashBalance && hasPlayers;
    }

    function performUpkeep() external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffelState)
            );
        }
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert("Time interval has not passed yet");
        }

        s_raffelState = RaffelState.CALCULATING;

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        (bool success, ) = winner.call{value: address(this).balance}("");

        s_raffelState = RaffelState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        if (!success) {
            revert Raffel__TransferFailed();
        }

        emit WinnerPicked(winner);
    }

    /** Getter Functions */
    function getEnteranceFee() public view returns (uint256) {
        return i_enteranceFee;
    }
}
