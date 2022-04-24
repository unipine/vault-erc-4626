// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC4626} from "solmate/mixins/ERC4626.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {ISwapRouter} from "uniswap/interfaces/ISwapRouter.sol";
import {TransferHelper} from "uniswap/libraries/TransferHelper.sol";

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {IController} from "../interfaces/IController.sol";

contract PowerVault is ERC4626 {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for ERC20;

    // Router
    ISwapRouter public immutable swapRouter;

    // REMEMBER TO DIVIDE BY 1e18 after multiplying
    uint256 COLLAT_RATIO = 1.5e18;

    // Minimum to mint REMEMBER TO DIVIDE BY 1e18
    uint256 MINIMUM_MINT = 69e17;

    // Uniswap ETH <> SQU pool
    address UNIoSQTH3 = 0x82c427AdFDf2d245Ec51D8046b41c4ee87F0d29C;

    // oSQTH token address
    address public constant oSQTH = 0xf1B99e3E573A1a9C5E6B2Ce818b617F0E664E86B;

    // WETH token address
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // eth wSQTH pool address
    address ethWSqueethPool = 0x0;

    // Pool fee of 0.3%
    uint24 public constant poolFee = 3000;

    uint256 public totalAssets = 0;
    uint256 public maxAssets = uint256(-1);
    uint256 private debt = 0;

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
    function beforeWithdraw(uint256 underlyingAmount, uint256 shares)
        internal
        override
    {
        uint256 collateralAmount = WETH9.balanceOf(address(this));
        // Gives us the amount of ETH to swap
        uint256 ethToWithdraw = _calcEthToWithdraw(shares, collateralAmount);
        // Swap WETH for oSQTH
        swapExactInputSingleSwap(ethToWithdraw, WETH9, oSQTH);
        // Burn oSQTH
        _burnWPowerPerp(msg.sender, debt, ethToWithdraw, false);
    }

    function afterDeposit(uint256 underlyingAmount, uint256 shares)
        internal
        override
    {
        uint256 collateralAmount = address(this).balance;

        // Check if we have hit collateralization ratio *mint minimum
        if (
            collateralAmount >
            MINIMUM_MINT * /* shouldn't this be *3/2 */
                COLLAT_RATIO
        ) {
            // Mint oSQTH
            (uint256 wSqueethToMint, ) = _calcWsqueethToMintAndFee(
                underlyingAmount,
                debt,
                collateralAmount
            );
            // mint wSqueeth and send it to msg.sender
            _mintWPowerPerp(
                msg.sender,
                wSqueethToMint,
                underlyingAmount,
                false
            );
            debt += wSqueethToMint;
            // Swap oSQTH for WETH9 in Uniswap V3 pool
            uint256 amountOut = swapExactInputSingleSwap(
                wSqueethToMint,
                oSQTH,
                WETH9
            );
        }
    }

    /**
     * @notice Swap for an exact amount based off of input
     * @param amountIn input amount
     * @return amountOut output amount of asset
     */
    function swapExactInputSingleSwap(
        uint256 amountIn,
        address assetIn,
        address assetOut
    ) internal returns (uint256 amountOut) {
        // msg.sender must approve this contract

        // Transfer the specified amount of DAI to this contract.
        TransferHelper.safeTransferFrom(
            assetIn,
            msg.sender,
            address(this),
            amountIn
        );
        // Approve the router to spend DAI.
        TransferHelper.safeApprove(assetIn, address(swapRouter), amountIn);

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: assetIn,
                tokenOut: assetOut,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
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
                WETH9,
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

    /**
     * @notice calculate ETH to withdraw from strategy given a ownership proportion
     * @param _shares shares
     * @param _strategyCollateralAmount amount of collateral in strategy
     * @return amount of ETH allowed to withdraw
     */
    function _calcEthToWithdraw(
        uint256 _shares,
        uint256 _strategyCollateralAmount
    ) internal pure returns (uint256) {
        return _strategyCollateralAmount.wmul(_shares.div(totalSupply));
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
