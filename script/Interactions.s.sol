// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
// Script to create VRF subscription
contract CreateSubscription is Script {
    // Creates subscription using config settings
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();

        // Get coordinator address from config
        address vrfCoordinatorV2_5 = helperConfig
            .getActiveNetworkConfig()
            .vrfCoordinatorV2_5;

        // Account address from config (currently unused)
        address account = helperConfig.getConfigByChainId(block.chainid).link;

        return createSubscription(vrfCoordinatorV2_5);
    }

    // Creates a new VRF subscription
    function createSubscription(
        address vrfCoordinatorV2_5
    ) public returns (uint256, address) {
        console.log("Creating subscription on chainId:", block.chainid);

        vm.startBroadcast(); // Start transaction
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5)
            .createSubscription();
        vm.stopBroadcast(); // End transaction

        console.log("Created subscription ID:", subId);
        return (subId, vrfCoordinatorV2_5);
    }

    // Main script entry point
    function run() external returns (uint256, address) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether; // 3 LINK

    function isLocalNetwork() internal view returns (bool) {
        return block.chainid == LOCAL_CHAIN_ID;
    }

    function FundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinatorV2_5 = helperConfig
            .getActiveNetworkConfig()
            .vrfCoordinatorV2_5;
        uint256 subscriptionId = helperConfig
            .getActiveNetworkConfig()
            .subscriptionId;
        address linkToken = helperConfig.getActiveNetworkConfig().link;
        fundSubscription(vrfCoordinatorV2_5, subscriptionId, linkToken);
    }

    function fundSubscription(
        address vrfCoordinatorV2_5,
        uint256 subscriptionId,
        address linkToken
    ) public {
        console.log("Funding SubscriptionId:", subscriptionId);
        console.log("Using vrfCoordinatorV2_5:", vrfCoordinatorV2_5);
        console.log("On chainId:", block.chainid);

        vm.startBroadcast();
        if (isLocalNetwork()) {
            VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fundSubscription(
                subscriptionId,
                FUND_AMOUNT
            );
        } else {
            LinkToken(linkToken).transferAndCall(
                vrfCoordinatorV2_5,
                FUND_AMOUNT,
                abi.encode(subscriptionId)
            );
        }
        vm.stopBroadcast();
    }

    function run() public {
        FundSubscriptionUsingConfig();
    }
}
