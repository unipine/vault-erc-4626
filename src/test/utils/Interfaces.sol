pragma solidity >=0.8.0;

import {ERC20} from "tribe-turbo/TurboMaster.sol";

interface Comptroller {
    function admin() external returns (address);

    function _addRewardsDistributor(address distributor)
        external
        returns (uint256);
}

abstract contract CErc20 is ERC20 {
    function mint(uint256 amount) external virtual returns (uint256);
}