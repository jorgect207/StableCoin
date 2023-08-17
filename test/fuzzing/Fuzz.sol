// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import "../../contracts/StableCoinToken.sol";
// import {Deploy} from "../script/deploy.sol";
import {Engine} from "../../contracts/Engine.sol";
import {Handle} from "./Handle.sol";

// import {helperDeploy} from "../script/helperDeploy.sol";
import {MockV3Aggregator} from "../Mocks/MockV3Aggregator.sol";
import "openzeppelin/mocks/ERC20Mock.sol";

contract Fuzz is StdInvariant, Test {
    StableCoinToken public stableCoinToken;
    Engine public engine;

    Handle public handle;

    // helperDeploy public helperDeployC;

    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    address public ethUsdPriceFeed;
    address public btcUsdPriceFeed;

    address public randomToken;

    address public weth;
    address public wbtc;
    uint256 public deployerKey;

    address public user = address(1);
    address public liquidator = address(2);

    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() external {
        // Deploy deployEngine = new Deploy();
        // (, helperDeployC) = deployEngine.run();
        // (weth, wbtc, ethUsdPriceFeed, btcUsdPriceFeed, deployerKey) = helperDeployC.constructorValues();
        // tokenAddresses = [weth, wbtc];
        // priceFeedAddresses = [ethUsdPriceFeed, btcUsdPriceFeed];
        // engine = new Engine(tokenAddresses,priceFeedAddresses);
        // console.log("weth", 1);

        // stableCoinToken = engine.stableCoin();
        // ERC20Mock(weth).mint(user, STARTING_USER_BALANCE);
        randomToken = (address(new ERC20Mock())); //weth
        weth = (address(new ERC20Mock())); //weth
        wbtc = (address(new ERC20Mock())); //wbtc
        ethUsdPriceFeed = (address(new MockV3Aggregator(8, 2000e8))); // eth-usd
        btcUsdPriceFeed = (address(new MockV3Aggregator(8, 20000e8))); //btc-usd

        // tokenAddresses.push(weth);
        // tokenAddresses.push(wbtc);
        // priceFeedAddresses.push(ethUsdPriceFeed);
        // priceFeedAddresses.push(btcUsdPriceFeed);

        tokenAddresses = [weth, wbtc];
        priceFeedAddresses = [ethUsdPriceFeed, btcUsdPriceFeed];

        engine = new Engine(tokenAddresses,priceFeedAddresses);

        stableCoinToken = engine.stableCoin();
        ERC20Mock(weth).mint(user, STARTING_USER_BALANCE);
        ERC20Mock(wbtc).mint(user, STARTING_USER_BALANCE);
        ERC20Mock(randomToken).mint(user, STARTING_USER_BALANCE);

        ERC20Mock(weth).mint(liquidator, STARTING_USER_BALANCE);

        handle = new Handle(stableCoinToken,engine);

        targetContract(address(handle)); // targuering the contract to engine, if you dont use this the fuzzer is gonna call all the contracts.
    }

    // the collateral in usd has to be greater than the mint usd
    function invariant_Test() public view {
        uint256 balanceWeth = ERC20Mock(weth).balanceOf(address(engine));
        uint256 balanceWbtc = ERC20Mock(wbtc).balanceOf(address(engine));

        uint256 balanceWethUsd = engine.getPirceUsd(weth, balanceWeth);
        uint256 balanceWbtcUsd = engine.getPirceUsd(wbtc, balanceWbtc);

        uint256 amountMintedUsd = stableCoinToken.totalSupply();

        console.log("total weth in usd: %s", balanceWethUsd);
        console.log("total wbtc in usd: %s", balanceWbtcUsd);
        console.log("total suply: %s", amountMintedUsd);
        console.log("total time call mint: %s", handle.numberOfTimeMint());

        assert(balanceWethUsd + balanceWbtcUsd >= amountMintedUsd);
    }
}
