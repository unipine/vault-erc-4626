pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import {FuseERC4626} from "fuse-flywheel/vaults/fuse/FuseERC4626.sol";
import {Addresses} from "./utils/Addresses.sol";
import {TurboMaster, ERC20, TurboSafe} from "tribe-turbo/TurboMaster.sol";
import {TurboBooster} from "tribe-turbo/modules/TurboBooster.sol";
import "forge-std/console.sol";

/// @notice Build yield generating strategies with Turbo and ERC-4626
contract BuildYieldStrategy is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    TurboMaster turboMaster;
    TurboBooster turboBooster;

    // TODO: Add support for a new asset
    address constant balAddress = 0xba100000625a3754423978a60c9317c58a424e3D;
    address constant balDAO = 0xb618F903ad1d00d6F7b92f5b0954DcdC056fC533;
    ERC20 bal = ERC20(balAddress);

    function setUp() public {
        turboMaster = TurboMaster(Addresses.TURBO_MASTER_ADDRESS);
        turboBooster = TurboBooster(Addresses.TURBO_BOOSTER_ADDRESS);
    }

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
        (TurboSafe safe, uint256 safeId) = turboMaster.createSafe(bal);
        assertGt(safeId, 0);
    }

    /// @notice Deposit collateral into the Turbo Safe
    function testDepositCollateralIntoStrategy() public {
        // Deposit into safe, verify deposited collateral
        vm.prank(Addresses.TURBO_ADMIN_ADDRESS);
        (TurboSafe safe, uint256 safeId) = turboMaster.createSafe(bal);

        uint256 amount = 100;
        address receiver = address(1);

        console.log("created");
        // Deposit collateral
        vm.startPrank(balDAO);
        bal.approve(address(safe), amount);
        safe.deposit(amount, receiver);
        vm.stopPrank();

        // Validate receiver was minted Safe Tokens
        uint256 receiverBalance = safe.balanceOf(receiver);
        assertGt(receiverBalance, 0);
    }

    /// @notice Boost the Safe (draw a loan out against it) and earn yield against that
    ///         strategy
    function testBoostSafeAndEarnYield() public {
        // Boost from safe, show yield accrewing
    }
}
