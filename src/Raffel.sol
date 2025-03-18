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

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts@1.3.0/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";

/**
 * @title A snample Raffel contract
 * @author Mohammad Sadeq Jafari
 * @notice This contract is for creating a sample raffel
 * @dev Implements Chainlink VRFv2.5
 */

contract Raffel {
    /**  Errors */
    error Raffel__SendMoreToEnterRaffel();

    uint256 private immutable i_enteranceFee;
    //  @dev the duration of the lottery in seconds
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;
    address payable[] private s_players;

    /**Events */

    event RaffelEnter(address indexed player);

    constructor(uint256 enteranceFee, uint256 interval) {
        i_enteranceFee = enteranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffel() external payable {
        // require(msg.value >= i_enteranceFee, "Not enough ETH sent!");
        // require(msg.value>=i_enteranceFee,Raffel__SendMoreToEnterRaffel());
        if (msg.value < i_enteranceFee) {
            revert Raffel__SendMoreToEnterRaffel();
        }
        s_players.push(payable(msg.sender));
        emit RaffelEnter(msg.sender);
    }

    function pickWinner() external {
        if ((block.timestamp - s_lastTimeStamp) > i_interval) {
            revert();
        }

        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
    }

    /**
     * Getter Functions
     */

    function getEnteranceFee() public view returns (uint256) {
        return i_enteranceFee;
    }
}
