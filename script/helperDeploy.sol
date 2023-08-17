// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Engine} from "../contracts/Engine.sol";
import {StableCoinToken} from "../contracts/StableCoinToken.sol";

import {MockV3Aggregator} from "../test/Mocks/MockV3Aggregator.sol";
import "openzeppelin/mocks/ERC20Mock.sol";

contract helperDeploy is Script {
    struct EngineConstructor {
        address weth;
        address btc;
        address priceFeedE;
        address priceFeedB;
        uint256 deployerKey;
    }

    EngineConstructor public constructorValues;

    uint256 public DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    constructor() {
        if (block.chainid == 11155111) {
            constructorValues = getSepholiaContract();
        } else {
            constructorValues = getMocks();
        }
    }

    function getSepholiaContract() public returns (EngineConstructor memory) {
        constructorValues.weth = (0xdd13E55209Fd76AfE204dBda4007C227904f0a81); //weth
        constructorValues.btc = (0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063); //wbtc
        constructorValues.priceFeedE = (0x694AA1769357215DE4FAC081bf1f309aDC325306); // eth-usd
        constructorValues.priceFeedB = (0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43); //btc-usd

        constructorValues.deployerKey = vm.envUint("PRIVATE_KEY");

        return constructorValues;
    }

    function getMocks() public returns (EngineConstructor memory) {
        vm.startBroadcast();

        constructorValues.weth = (address(new ERC20Mock())); //weth
        constructorValues.btc = (address(new ERC20Mock())); //wbtc
        constructorValues.priceFeedE = (address(new MockV3Aggregator(8, 1000))); // eth-usd
        constructorValues.priceFeedB = (address(new MockV3Aggregator(8, 20000))); //btc-usd

        vm.stopBroadcast();
        constructorValues.deployerKey = DEFAULT_ANVIL_PRIVATE_KEY;

        return constructorValues;
    }
}
