// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {ERC20Permit} from "openzeppelin/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "openzeppelin/token/ERC20/extensions/ERC20Votes.sol";

contract DaoToken is ERC20, ERC20Permit, ERC20Votes {
    uint256 public mintTokens = 1_000_000 * 10e18;

    constructor(address _to) ERC20("MyToken", "MTK") ERC20Permit("MyToken") {
        _mint(_to, mintTokens);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }
}
