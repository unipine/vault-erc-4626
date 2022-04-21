// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import {FuseERC4626} from "fuse-flywheel/vaults/fuse/FuseERC4626.sol";
import {Addresses} from "./utils/Addresses.sol";

/// @notice Build yield generating strategies with Turbo and ERC-4626
contract BuildYieldStrategy is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    function setUp() public {}

    /// @notice Create an ERC-4626 strategy
    function testDeployERC4626Strategy() public {
        string memory name = "coolStrat";
        string memory symbol = "COOL";
        FuseERC4626 strategy = new FuseERC4626(Addresses.C_TOKEN, name, symbol);

        assertEq(strategy.name(), name);
        assertEq(strategy.symbol(), symbol);
    }

    /// @notice Create a Turbo safe, to use the created strategy
    function testCreateTurboSafeWithStrategy() public {
        vm.prank(Addresses.TURBO_ADMIN_ADDRESS);

        // Create a Safe, with supported collateral
    }

    /// @notice Deposit collateral into the Turbo Safe
    function testDepositCollateralIntoStrategy() public {
        // Deposit into safe, verify deposited collateral
    }

    /// @notice Boost the Safe (draw a loan out against it) and earn yield against that
    ///         strategy
    function testBoostSafeAndEarnYield() public {
        // Boost from safe, show yield accrewing
    }
}
