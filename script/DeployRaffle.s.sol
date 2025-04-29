// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Import dependencies
import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/Raffel.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription} from "./Interactions.s.sol";

/**
 * @title DeployRaffel
 * @dev Script contract for deploying Raffel contract with proper configuration
 */
contract DeployRaffel is Script {
    /**
     * @dev Main script entry point
     * @return Raffel instance and HelperConfig instance
     */
    function run() external returns (Raffle, HelperConfig) {
        return deployRaffle();
    }

    /**
     * @dev Deploys Raffel contract with network configuration
     * @return deployed Raffel contract and HelperConfig instance
     */
    function deployRaffle() public returns (Raffle, HelperConfig) {
        // Initialize helper config to get network parameters
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig
            .getActiveNetworkConfig();

        // Create new subscription if one doesn't exist
        if (config.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (
                config.subscriptionId,
                config.vrfCoordinatorV2_5
            ) = createSubscription.run();
        }

        // Broadcast and deploy Raffel contract
        vm.startBroadcast();
        Raffle raffel = new Raffle(
            config.raffleEntranceFee,
            config.automationUpdateInterval,
            config.vrfCoordinatorV2_5,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        return (raffel, helperConfig);
    }
}
