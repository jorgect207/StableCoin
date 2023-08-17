// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title Stable Coin
 * @author jorgect
 * @notice Stable coin plegged to dollar
 */

import "openzeppelin/token/ERC20/extensions/ERC20Burnable.sol";
import "openzeppelin/access/Ownable.sol";

contract StableCoinToken is ERC20Burnable, Ownable {
    error _zeroNo();
    error _noMoreBalance();

    constructor() payable ERC20("StableCoin", "SCJ") {}

    function burn(uint256 _amount) public override onlyOwner {
        if (_amount <= 0) {
            revert _zeroNo();
        }
        uint256 balanceUser = balanceOf(msg.sender);
        if (_amount > balanceUser) {
            revert _noMoreBalance();
        }
        super.burn(_amount);
    }

    function mint(uint256 _amount, address _to) external onlyOwner returns (bool) {
        if (_amount == 0) {
            revert _zeroNo();
        }
        if (_to == address(0)) {
            revert _zeroNo();
        }
        _mint(_to, _amount);
        return true;
    }
}
