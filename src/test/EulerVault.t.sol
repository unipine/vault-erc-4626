pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import {Vm} from "forge-std/Vm.sol";
import {FuseERC4626} from "fuse-flywheel/vaults/fuse/FuseERC4626.sol";
import {Addresses} from "./utils/Addresses.sol";
import {TurboMaster, ERC20, TurboSafe} from "tribe-turbo/TurboMaster.sol";
import {TurboBooster} from "tribe-turbo/modules/TurboBooster.sol";
import {FuseFlywheelCore, IFlywheelBooster, Authority} from "fuse-flywheel/FuseFlywheelCore.sol";
import {FuseFlywheelDynamicRewards} from "fuse-flywheel/rewards/FuseFlywheelDynamicRewards.sol";
import {Comptroller, CErc20} from "./utils/Interfaces.sol";

import {EulerVault} from "../EulerVault.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

/// @notice Build yield generating strategies with Turbo and ERC-4626
contract EulerVaultTest is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);
    // https://docs.uniswap.org/protocol/reference/deployments MAINNET RN
    address weth_whale = 0x6555e1CC97d3cbA6eAddebBCD7Ca51d75771e0B8;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    ERC20 wethToken = MockERC20(WETH);
    MockERC20 underlying;
    EulerVault vault;
    address constant alice = address(1);

    function setUp() public {
        uint256 number = 43;
        assertEq(number, 43);
        console.log("deploy MockERC20");
        underlying = new MockERC20("Mock Token", "TKN", 18);
        console.log("here");
        // vault = new EulerVault(underlying, "Short SQTH Vault", "PPP-WETH");
        console.log("post deploy");

        // Give Alice some mock tokens, ~$315k worth
        // underlying.mint(alice, 2_000e18);
    }

    function testDeposit() public {
        vm.prank(alice);
        vault.deposit(2000e18, alice);
    }
    // /// @notice Create a Turbo safe, to use the created strategy
    // function testCreateTurboSafeWithStrategy() public {}

    // /// @notice Deposit collateral into the Turbo Safe
    // function testDepositCollateralIntoStrategy() public {
    //     // 1. Create Safe and transfer ownership to Alice
    //     vm.startPrank(Addresses.TURBO_ADMIN_ADDRESS);
    //     (TurboSafe safe, uint256 safeId) = turboMaster.createSafe(bal);
    //     safe.setOwner(alice);
    //     vm.stopPrank();

    //     // 2. Deposit collateral into the safe - this can later be drawn against
    //     uint256 amount = 100;
    //     address receiver = address(1);

    //     // Deposit collateral
    //     vm.startPrank(alice);
    //     bal.approve(address(safe), amount);
    //     safe.deposit(amount, receiver);
    //     vm.stopPrank();

    //     // Validate Alice received her tokens!
    //     uint256 aliceBalance = safe.balanceOf(receiver);
    //     assertGt(aliceBalance, 0);
    // }

    // /// @notice Boost the Safe (draw a loan out against it) and earn yield against that
    // ///         strategy
    // function testBoostSafeAndEarnYield() public {
    //     // 1. Create Safe and transfer ownership to Alice
    //     vm.startPrank(Addresses.TURBO_ADMIN_ADDRESS);
    //     (TurboSafe safe, uint256 safeId) = turboMaster.createSafe(bal);
    //     safe.setOwner(alice);
    //     vm.stopPrank();

    //     // 2. Deposit collateral into the safe - this can later be drawn against
    //     uint256 amount = 1400e18; // units of Bal, ~$20k
    //     address receiver = address(1);

    //     // Deposit collateral
    //     vm.startPrank(alice);
    //     bal.approve(address(safe), amount);
    //     safe.deposit(amount, receiver);
    //     vm.stopPrank();

    //     assertEq(safe.balanceOf(alice), amount);

    //     // 3. Boost the safe, draw a costless Fei loan against the collateral
    //     //    and deposit it into the strategy to earn yield
    //     uint256 boostAmount = 3100e18; // units of fei, ~$4k
    //     vm.prank(alice);
    //     safe.boost(strategy, boostAmount);

    //     assertEq(strategy.balanceOf(address(safe)), boostAmount);
    // }

    // //////////  FLYWHEEL /////////////

    // /// @notice Setup a flywheel for a fuse pool
    // function testAddAFlywheelToAFusePool() public {
    //     // Get the comptroller for a fuse pool that we'll add rewards to: Pool 156
    //     Comptroller comptroller = Comptroller(
    //         Addresses.FUSE_POOL_156_COMPTROLLER_ADDRESS
    //     );

    //     // Get a reward token that we will distribute to the pool
    //     ERC20 rewardToken = ERC20(Addresses.CONVEX_TOKEN);

    //     // Deploy the flywheel core - handles accounting
    //     FuseFlywheelCore flywheel = new FuseFlywheelCore(
    //         rewardToken,
    //         FuseFlywheelDynamicRewards(address(0)),
    //         IFlywheelBooster(address(0)),
    //         address(this),
    //         Authority(address(0))
    //     );

    //     // Create the rewards module - this particular module will  transfers rewards linearly
    //     // over a reward cyle (7 days here)
    //     FuseFlywheelDynamicRewards rewards = new FuseFlywheelDynamicRewards(
    //         flywheel,
    //         7 days
    //     );

    //     // Hook up to the flywheel
    //     flywheel.setFlywheelRewards(rewards);

    //     // Attach a fuse pool to the flywheel, to distribute rewards
    //     CErc20 fusePool = CErc20(Addresses.fUST3_POOL);
    //     flywheel.addMarketForRewards(fusePool);
    //     vm.prank(comptroller.admin());
    //     comptroller._addRewardsDistributor(address(flywheel));
    // }
}
