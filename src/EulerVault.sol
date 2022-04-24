// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC4626} from "solmate/mixins/ERC4626.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {ISwapRouter} from "uniswap/interfaces/ISwapRouter.sol";
import {TransferHelper} from "uniswap/libraries/TransferHelper.sol";

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

contract PowerVault is ERC4626 {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for ERC20;

    // Router
    ISwapRouter public immutable swapRouter;

    // REMEMBER TO DIVIDE after multiplying
    uint256 COLLAT_RATIO = 2;

    // Minimum to mint REMEMBER TO DIVIDE BY 1e18
    uint256 MINIMUM_MINT = 69e17;

    // Uniswap ETH <> SQU pool
    address UNIoSQTH3 = 0x82c427AdFDf2d245Ec51D8046b41c4ee87F0d29C;

    // oSQTH token address
    address public constant oSQTH = 0xf1B99e3E573A1a9C5E6B2Ce818b617F0E664E86B;

    // Ropsten Euler markets
    address public constant EULER_MARKETS = 0x60Ec84902908f5c8420331300055A63E6284F522;

    // WETH token address
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    
    // eth wSQTH pool address
    address ethWSqueethPool = 0x0;

    // Pool fee of 0.3%
    uint24 public constant poolFee = 3000;

    uint256 public constant hedgingTwapPeriod = 180;

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

    // Vault has WETH
    // Swap user portion of WETH in Uniswap WETH<>oSQTH pool (this gives user oSQTH)
    // Partially repay oSQTH loan
    // Unlock WETH collateral
    function beforeWithdraw(uint256 underlyingAmount, uint256 shares)
        internal
        override
    {
        uint256 collateralAmount = WETH9.balanceOf(address(this));
        // Gives us the amount of ETH to swap
        uint256 ethToWithdraw = _calcEthToWithdraw(shares, collateralAmount);
        // Swap WETH for oSQTH
        swapExactInputSingleSwap(ethToWithdraw, WETH9, oSQTH);
        // Unlock WETH collateral
        // Later on, to repay the 2 tokens plus interest:
        IERC20(oSQTH).approve(EULER_MAINNET, type(uint).max);
        borrowedDToken.repay(0, shares);
    }

    // Vault has WETH
    // Supply WETH as collateral
    // Borrow oSQTH
    // Sell oSQTH for WETH on Uniswap
    function afterDeposit(uint256 underlyingAmount, uint256 shares)
        internal
        override
    {
        // Use the markets module:
        IEulerMarkets markets = IEulerMarkets(EULER_MAINNET_MARKETS);

        // Approve, get eToken addr, and deposit:
        IERC20(WETH9).approve(EULER_MAINNET, type(uint).max);
        IEulerEToken collateralEToken = IEulerEToken(markets.underlyingToEToken(WETH9));
        collateralEToken.deposit(0, underlyingAmount);

        // Enter the collateral market (collateral's address, *not* the eToken address):
        markets.enterMarket(0, address(WETH9));

        // Get the dToken address of the borrowed asset: SQTH
        IEulerDToken borrowedDToken = IEulerDToken(markets.underlyingToDToken(oSQTH));

        // Borrow 2 tokens (assuming 18 decimal places).
        // The 2 tokens will be sent to your wallet (ie, address(this)).
        // This automatically enters you into the borrowed market.

        //wrap?

        // Get number of squeeth we can borrow
        uint256 wSqueethEthPrice = IOracle(oracle).getTwap(
                UNIoSQTH3,
                oSQTH,
                WETH9,
                hedgingTwapPeriod,
                true
            );

        uint256 squeethToBorrow = (underlyingAmount * wSqueethEthPrice) / COLLAT_RATIO;
        borrowedDToken.borrow(0, squeethToBorrow);

        totalSupply += borrowedDToken.balanceOf(address(this));
        
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
