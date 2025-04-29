// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {Raffle} from "src/Raffel.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DeployRaffel} from "script/DeployRaffle.s.sol";
/**
 * @title RaffleTest
 * @notice Test contract for Raffle functionality
 * @dev Uses Foundry's Test framework for testing Raffle contract
 */
contract RaffleTest is Test {
    /*//////////////////////////////////////////////////////////////
                                STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    Raffle public raffle;
    HelperConfig public helperConfig;

    // Test constants
    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    // Configuration variables
    uint256 public entranceFee;
    uint256 public interval;
    address public vrfCoordinator;
    bytes32 public gasLane;
    uint256 public subscriptionId;
    uint32 public callbackGasLimit;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    event RaffleEnter(address indexed participant);
    event WinnerPicked(address indexed winner);

    /*//////////////////////////////////////////////////////////////
                                SETUP
    //////////////////////////////////////////////////////////////*/
    function setUp() external {
        DeployRaffel deployRaffle = new DeployRaffel();
        (raffle, helperConfig) = deployRaffle.deployRaffle();

        HelperConfig.NetworkConfig memory config = helperConfig
            .getActiveNetworkConfig();

        // Set configuration parameters
        entranceFee = config.raffleEntranceFee;
        interval = config.automationUpdateInterval;
        vrfCoordinator = config.vrfCoordinatorV2_5;
        gasLane = config.gasLane;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;

        // Fund test player
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    /*//////////////////////////////////////////////////////////////
                            INITIAL STATE TESTS
    //////////////////////////////////////////////////////////////*/
    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    /*//////////////////////////////////////////////////////////////
                            ENTER RAFFLE TESTS
    //////////////////////////////////////////////////////////////*/
    function testRaffleRevertWhenYouDontPayEnough() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        address playerRecorded = raffle.getPlayer(0);
        assertEq(playerRecorded, PLAYER);
    }

    function testEnteringRaffleEmitsEvent() public {
        vm.prank(PLAYER);

        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEnter(PLAYER);

        raffle.enterRaffle{value: entranceFee}();
    }

    function testDontAllowPlayerEnterWhileRaffleIsCalculating() public {
        // Enter raffle
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        // Fast forward time and trigger upkeep
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep();

        // Try to enter again
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        raffle.enterRaffle{value: entranceFee}();
    }
}
