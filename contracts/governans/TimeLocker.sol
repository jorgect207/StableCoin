// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {TimelockController} from "openzeppelin/governance/TimelockController.sol";

contract TimeLocker is TimelockController {
    constructor(uint256 minDelay, address[] memory proposers, address[] memory executors, address admin)
        TimelockController(minDelay, proposers, executors, admin)
    {}
}
