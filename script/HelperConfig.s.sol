// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

/**
 * @title CodeConstants
 * @dev Contains common constants and default values used across contracts
 */
abstract contract CodeConstants {
    // Mock pricing parameters for VRF
    uint96 public constant MOCK_BASE_FEE = 0.25 ether;
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9;
    int256 public constant MOCK_WEI_PER_UINT_LINK = 4e15; // LINK/ETH price ratio

    // Default sender address for Foundry tests
    address public constant FOUNDRY_DEFAULT_SENDER =
        0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    // Chain IDs
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

/**
 * @title HelperConfig
 * @dev Provides network configurations for different chains and manages VRF setup
 */
contract HelperConfig is CodeConstants, Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        uint256 subscriptionId; // Chainlink subscription ID
        bytes32 gasLane; // Key hash for VRF
        uint256 automationUpdateInterval; // Interval for automation checks
        uint256 raffleEntranceFee; // Entry fee for raffle
        uint32 callbackGasLimit; // Gas limit for callback
        address vrfCoordinatorV2_5; // VRF coordinator address
        address link; // Default account address

    }

    NetworkConfig public localNetworkConfig; // Configuration for local/anvil network
    mapping(uint256 chainId => NetworkConfig) public networkConfigs; // ChainId to config mapping

    constructor() {
        // Initialize configs for known networks
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
        networkConfigs[ETH_MAINNET_CHAIN_ID] = getMainnetEthConfig();
    }

    /**
     * @dev Gets config for current active network
     */
    function getActiveNetworkConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    /**
     * @dev Gets network config by chain ID
     * @param chainId The chain ID to get config for
     */
    function getConfigByChainId(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinatorV2_5 != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    /**
     * @dev Returns mainnet Ethereum configuration
     */
    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                subscriptionId: 0, // Will be created if 0
                gasLane: 0x9fe0eebf5e446e3c998ec9bb19951541aee00bb90ea201ae456421a2ded86805,
                automationUpdateInterval: 30,
                raffleEntranceFee: 0.01 ether,
                callbackGasLimit: 500000,
                vrfCoordinatorV2_5: 0x271682DEB8C4E0901D1a1550aD2e64D568E69909,
                link: 0x779877A7B0D9E8603169DdbD7836e478b4624789
            });
    }

    /**
     * @dev Returns Sepolia testnet configuration
     */
    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                subscriptionId: 87235897063600979283419035053874758060744414843030125127407171539033774744532, // Will be created if 0
                gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                automationUpdateInterval: 30,
                raffleEntranceFee: 0.01 ether,
                callbackGasLimit: 500000,
                vrfCoordinatorV2_5: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                link: 0x779877A7B0D9E8603169DdbD7836e478b4624789
            });
    }

    /**
     * @dev Creates or returns local Anvil network configuration
     */
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.vrfCoordinatorV2_5 != address(0)) {
            return localNetworkConfig;
        }

        console2.log(unicode"⚠️ Deploying mock contract...");
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorV2_5Mock = new VRFCoordinatorV2_5Mock(
                MOCK_BASE_FEE,
                MOCK_GAS_PRICE_LINK,
                MOCK_WEI_PER_UINT_LINK
            );
        LinkToken linkToken = new LinkToken();
        uint256 subscriptionId = vrfCoordinatorV2_5Mock.createSubscription();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            subscriptionId: subscriptionId,
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            automationUpdateInterval: 30,
            raffleEntranceFee: 0.01 ether,
            callbackGasLimit: 500000,
            vrfCoordinatorV2_5: address(vrfCoordinatorV2_5Mock),
            link: address(linkToken)
        });

        vm.deal(localNetworkConfig.link, 100 ether);
        return localNetworkConfig;
    }
}
