// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Engine} from "../contracts/Engine.sol";
import {StableCoinToken} from "../contracts/StableCoinToken.sol";

import {helperDeploy} from "./helperDeploy.sol";

contract Deploy is Script {
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function run() public returns (Engine, helperDeploy) {
        helperDeploy deployValues = new helperDeploy();
        (address weth, address wbtc, address priceFeedE, address priceFeedB,) = deployValues.constructorValues();
        tokenAddresses = [weth, wbtc];
        priceFeedAddresses = [priceFeedE, priceFeedB];

        vm.startBroadcast();
        Engine engineContract = new Engine(tokenAddresses,priceFeedAddresses);

        vm.stopBroadcast();
        return (engineContract, deployValues);
    }
}
