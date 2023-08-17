// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../contracts/StableCoinToken.sol";
// import {Deploy} from "../script/deploy.sol";
import {Engine} from "../contracts/Engine.sol";
// import {helperDeploy} from "../script/helperDeploy.sol";
import {MockV3Aggregator} from "../test/Mocks/MockV3Aggregator.sol";
import "openzeppelin/mocks/ERC20Mock.sol";

contract EngineTest is Test {
    StableCoinToken public stableCoinToken;
    Engine public engine;

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
    }

    // function testProve() external {
    //     uint256 prove = 1;
    //     assertEq(prove, 1);
    // }

    //test contructor//

    address[] public tokens;
    address[] public priceFeeds;

    function testConstructorLength() external {
        tokens.push(weth);
        tokens.push(wbtc);

        priceFeeds.push(ethUsdPriceFeed);

        vm.expectRevert(Engine.NO_LENGTH.selector);

        engine = new Engine(tokens,priceFeeds);
    }

    //test pricefeeds//

    function testPirceFeed() external {
        uint256 amountEth = 1e18;
        uint256 amountUsdExpected = 2000e18;
        (, int256 price,,,) = MockV3Aggregator(ethUsdPriceFeed).latestRoundData();

        uint256 usdValue = engine.getPirceUsd(weth, amountEth);

        assertEq(uint256(price), 2000e8);
        assertEq(usdValue, amountUsdExpected);
    }

    //test deposit collateral//
    function testDepositCollateral() public {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(engine), 2 ether);

        engine.depositCollateral(weth, 2 ether);
        uint256 balance = engine.getBalanceCollateralUser(user, weth);

        vm.stopPrank();
        assertEq(balance, 2 ether);
    }

    function testDepositTwoCollateral() public {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(engine), 2 ether);
        ERC20Mock(wbtc).approve(address(engine), 2 ether);

        engine.depositCollateral(weth, 2 ether);
        engine.depositCollateral(wbtc, 1 ether);

        uint256 balanceWeth = engine.getBalanceCollateralUser(user, weth);
        uint256 balanceWbtc = engine.getBalanceCollateralUser(user, wbtc);

        vm.stopPrank();
        assertEq(balanceWeth, 2 ether);
        assertEq(balanceWbtc, 1 ether);
    }

    function testDepositZeroCollateral() external {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(engine), 2 ether);
        vm.expectRevert(Engine.NON_ZERO_VALUE.selector);

        engine.depositCollateral(weth, 0 ether);
        vm.stopPrank();
    }

    function testDepositNoToken() external {
        vm.startPrank(user);
        ERC20Mock(randomToken).approve(address(engine), 2 ether);
        vm.expectRevert(Engine.NO_TOKEN.selector);

        engine.depositCollateral(randomToken, 2 ether);
        vm.stopPrank();
    }

    // test mint //
    function testMint() external {
        testDepositCollateral();
        vm.startPrank(user);

        engine.mintToken(2000e18);
        uint256 balanceMinted = engine.mintedStable(user);

        vm.stopPrank();

        assertEq(balanceMinted, 2000e18);
    }

    function testMintBadCollateral() external {
        testDepositCollateral();
        vm.startPrank(user);
        vm.expectRevert(Engine.NO_ENOUGHT_COLLATERAL.selector);
        engine.mintToken(2001e18);

        vm.stopPrank();
    }

    //test deposit collateral//
    function testDepositCollateralAndMintToken() public returns (uint256 balanceCollateral, uint256 balanceMint) {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(engine), 2 ether);

        engine.depositCollateralAndMintToken(weth, 2 ether, 2000e18);

        balanceCollateral = engine.getBalanceCollateralUser(user, weth);
        balanceMint = engine.mintedStable(user);

        vm.stopPrank();

        assertEq(2 ether, balanceCollateral);
        assertEq(2000e18, balanceMint);
    }

    // test reedem//
    function testRedeemCollateral() public {
        testDepositCollateral();
        vm.startPrank(user);

        engine.redeemCollateral(weth, 2 ether);
        vm.stopPrank();
        uint256 balanceCollateral = engine.getBalanceCollateralUser(user, weth);

        assertEq(balanceCollateral, 0);
    }

    function testRedeemCollateralZeroValue() public {
        testDepositCollateral();
        vm.startPrank(user);
        vm.expectRevert(Engine.NON_ZERO_VALUE.selector);
        engine.redeemCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRedeemCollateralForToken() public {
        (uint256 balanceCollateral, uint256 balanceMint) = testDepositCollateralAndMintToken();
        vm.startPrank(user);
        stableCoinToken.approve(address(engine), balanceMint);
        engine.redeemCollateralForToken(balanceMint, weth, balanceCollateral);
        uint256 balanceMintAfter = engine.mintedStable(user);
        uint256 balanceCollateralAfter = engine.getBalanceCollateralUser(user, weth);
        vm.stopPrank();
        assertEq(balanceMintAfter, 0);
        assertEq(balanceCollateralAfter, 0);
    }

    function testRedeemCollateralForTokenRevertIfNotHealth() public {
        (, uint256 balanceMint) = testDepositCollateralAndMintToken();
        vm.startPrank(user);
        stableCoinToken.approve(address(engine), balanceMint);
        vm.expectRevert(Engine.NO_ENOUGHT_COLLATERAL.selector);
        engine.redeemCollateralForToken(100e18, weth, 1 ether);

        vm.stopPrank();
    }

    // test burning//
    function testBurnToken() public {
        (uint256 balanceCollateral, uint256 balanceMintBefore) = testDepositCollateralAndMintToken();
        vm.startPrank(user);
        stableCoinToken.approve(address(engine), balanceMintBefore);
        engine.burnToken(balanceMintBefore);
        uint256 balanceMintAfter = engine.mintedStable(user);
        uint256 balanceCollateralAfter = engine.getBalanceCollateralUser(user, weth);

        vm.stopPrank();
        assertEq(balanceMintAfter, 0);
        assertEq(balanceCollateralAfter, balanceCollateral);
    }

    function testBurnTokenHalf() public {
        (uint256 balanceCollateral, uint256 balanceMintBefore) = testDepositCollateralAndMintToken();
        vm.startPrank(user);
        stableCoinToken.approve(address(engine), balanceMintBefore);
        engine.burnToken(1000e18);
        uint256 balanceMintAfter = engine.mintedStable(user);
        uint256 balanceCollateralAfter = engine.getBalanceCollateralUser(user, weth);

        vm.stopPrank();
        assertEq(balanceMintAfter, 1000e18);
        assertEq(balanceCollateralAfter, balanceCollateral);
    }

    // test liquidation//
    function testLiquidate() public {
        (, uint256 balanceMintBefore) = testDepositCollateralAndMintToken();
        //update price of eth so user is gonna have bad health factor
        MockV3Aggregator(ethUsdPriceFeed).updateAnswer(1500e8);
        vm.startPrank(liquidator);
        //mint usd for liquidator approve, deposit collateral and mint
        ERC20Mock(weth).approve(address(engine), STARTING_USER_BALANCE);
        engine.depositCollateralAndMintToken(weth, STARTING_USER_BALANCE, 3000e18);
        //
        stableCoinToken.approve(address(engine), balanceMintBefore);
        engine.liquidateAll(weth, user, balanceMintBefore);

        uint256 balanceMintAfter = engine.mintedStable(user);
        console.log(balanceMintAfter);
        uint256 balanceCollateralAfter = engine.getBalanceCollateralUser(user, weth);
        console.log(balanceCollateralAfter);

        vm.stopPrank();
        assertEq(balanceMintAfter, 0); //666666666666666667
        assertEq(balanceCollateralAfter, 0);
    }
}
