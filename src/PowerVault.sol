// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {ERC4626} from "solmate/mixins/ERC4626.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {IOracle} from "../interfaces/IOracle.sol";

contract PowerVault is ERC4626 {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for ERC20;

    // REMEMBER TO DIVIDE BY 1e18 after multiplying
    uint256 COLLAT_RATIO = 1.5e18;

    // Minimum to mint REMEMBER TO DIVIDE BY 1e18
    uint256 MINIMUM_MINT = 69e17;

    // Uniswap ETH <> SQU pool
    address UNIoSQTH3 = 0x82c427AdFDf2d245Ec51D8046b41c4ee87F0d29C;

    // oSQTH token address
    address oSQTH = 0xf1B99e3E573A1a9C5E6B2Ce818b617F0E664E86B;

    uint256 public totalAssets = 0;
    uint256 public maxAssets = uint256(-1);

    constructor(
        address _asset,
        string memory name,
        string memory symbol
    ) {
        _asset = asset;
    }

    // Vault has ETH
    // Swap user portion of ETH in Uniswap ETH<>oSQTH pool (this gives user oSQTH)
    // Burn oSQTH to unlock collateral (in ETH)
    // Collateral gets sent to user
    function beforeWithdraw(uint256 underlyingAmount, uint256)
        internal
        override
    {}

    function afterDeposit(uint256 underlyingAmount, uint256) internal override {
        uint256 collateralAmount = address(this).balance;

        // Check if we have hit collateralization ratio *mint minimum
        if (
            collateralAmount >
            MINIMUM_MINT * /* shouldn't this be *3/2 */
                COLLAT_RATIO
        ) {
            // Mint oSQTH
            (
                uint256 wSqueethToMint,
                uint256 ethFee
            ) = _calcWsqueethToMintAndFee(underlyingAmount, collateralAmount);
            // mint wSqueeth and send it to msg.sender
            _mintWPowerPerp(
                msg.sender,
                wSqueethToMint,
                underlyingAmount,
                false
            );
            // Swap oSQTH for ETH in Uniswap V3 pool
            // dont delete ^ sincerely, ratan
        }
    }

    /**
     * @notice calculate amount of wSqueeth to mint and fee paid from deposited amount
     * @param _depositedAmount amount of deposited WETH
     * @param _strategyDebtAmount amount of strategy debt
     * @param _strategyCollateralAmount collateral amount in strategy
     * @return amount of minted wSqueeth and ETH fee paid on minted squeeth
     */
    function _calcWsqueethToMintAndFee(
        uint256 _depositedAmount,
        uint256 _strategyDebtAmount,
        uint256 _strategyCollateralAmount
    ) internal view returns (uint256, uint256) {
        uint256 wSqueethToMint;
        uint256 feeAdjustment = _calcFeeAdjustment();

        if (_strategyDebtAmount == 0 && _strategyCollateralAmount == 0) {
            require(totalSupply() == 0, "Crab contracts shut down");

            uint256 wSqueethEthPrice = IOracle(oracle).getTwap(
                ethWSqueethPool,
                wPowerPerp,
                weth,
                hedgingTwapPeriod,
                true
            );
            uint256 squeethDelta = wSqueethEthPrice.wmul(2e18);
            wSqueethToMint = _depositedAmount.wdiv(
                squeethDelta.add(feeAdjustment)
            );
        } else {
            wSqueethToMint = _depositedAmount.wmul(_strategyDebtAmount).wdiv(
                _strategyCollateralAmount.add(
                    _strategyDebtAmount.wmul(feeAdjustment)
                )
            );
        }

        uint256 fee = wSqueethToMint.wmul(feeAdjustment);

        return (wSqueethToMint, fee);
    }

    // no need with public total Assets
    // /// @notice Total amount of the underlying asset that
    // /// is "managed" by Vault.
    // function totalAssets() public view override returns (uint256) {}

    // /// @notice maximum amount of assets that can be deposited.
    // function maxDeposit(address) public view override returns (uint256) {}

    /// @notice maximum amount of shares that can be minted.
    function maxMint(address) public view override returns (uint256) {}

    /// @notice Maximum amount of assets that can be withdrawn.
    function maxWithdraw(address owner)
        public
        view
        override
        returns (uint256)
    {}

    /// @notice Maximum amount of shares that can be redeemed.
    function maxRedeem(address owner) public view override returns (uint256) {}
}
