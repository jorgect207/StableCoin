    // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import "../../contracts/StableCoinToken.sol";
// import {Deploy} from "../script/deploy.sol";
import {Engine} from "../../contracts/Engine.sol";

// import {helperDeploy} from "../script/helperDeploy.sol";
import {MockV3Aggregator} from "../Mocks/MockV3Aggregator.sol";
import "openzeppelin/mocks/ERC20Mock.sol";

contract Handle is Test {
    StableCoinToken public stableCoinToken;
    Engine public engine;

    // helperDeploy public helperDeployC;

    uint256 public numberOfTimeMint;

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

    uint96 public constant MAX_DEPOSIT_SIZE = type(uint96).max;

    constructor(StableCoinToken _stableCoinToken, Engine _engine) {
        stableCoinToken = _stableCoinToken;
        engine = _engine;

        address[] memory tokenAddressesM = engine.getToken();
        address[] memory priceFeedAddressesM = engine.getPriceFeed();

        for (uint256 i; i < tokenAddressesM.length;) {
            tokenAddresses.push(tokenAddressesM[i]);
            priceFeedAddresses.push(priceFeedAddressesM[i]);

            unchecked {
                ++i;
            }
        }

        ethUsdPriceFeed = priceFeedAddresses[0];
        btcUsdPriceFeed = priceFeedAddresses[1];

        weth = tokenAddresses[0];
        wbtc = tokenAddresses[1];
    }

    function depositCollateral(uint256 _tokenIndex, uint256 _amount) public {
        _tokenIndex = bound(_tokenIndex, 0, tokenAddresses.length - 1);
        _amount = bound(_amount, 1, MAX_DEPOSIT_SIZE);

        ERC20Mock collateralToken = ERC20Mock(tokenAddresses[_tokenIndex]);

        vm.startPrank(msg.sender);
        collateralToken.mint(msg.sender, _amount);
        collateralToken.approve(address(engine), _amount);

        engine.depositCollateral(tokenAddresses[_tokenIndex], _amount);
        vm.stopPrank();
    }

    function depositCollateralAndMintToken(uint256 _tokenIndex, uint256 _amount, uint256 _amountToMint) public {
        _tokenIndex = bound(_tokenIndex, 0, tokenAddresses.length - 1);
        _amount = bound(_amount, 1, MAX_DEPOSIT_SIZE);

        ERC20Mock collateralToken = ERC20Mock(tokenAddresses[_tokenIndex]);

        vm.startPrank(msg.sender);
        collateralToken.mint(msg.sender, _amount);
        collateralToken.approve(address(engine), _amount);

        engine.depositCollateralAndMintToken(tokenAddresses[_tokenIndex], _amount, _amountToMint);
        vm.stopPrank();
    }

    function mintToken(uint256 _amount) public {
        vm.startPrank(msg.sender);
        engine.mintToken(_amount);
        vm.stopPrank();
        numberOfTimeMint++;
    }

    function redeemCollateral(uint256 _tokenIndex, uint256 _amount) public {
        _tokenIndex = bound(_tokenIndex, 0, tokenAddresses.length - 1);

        ERC20Mock collateralToken = ERC20Mock(tokenAddresses[_tokenIndex]);
        uint256 collateralBalance = engine.getBalanceCollateralUser(msg.sender, address(collateralToken));

        if (collateralBalance == 0) {
            return;
        }
        _amount = bound(_amount, 1, collateralBalance);

        vm.startPrank(msg.sender);

        engine.redeemCollateral(tokenAddresses[_tokenIndex], _amount);
        vm.stopPrank();
    }

    function burnToken(uint256 _amount) public {
        if (stableCoinToken.balanceOf(msg.sender) == 0) {
            return;
        }
        _amount = bound(_amount, 1, stableCoinToken.balanceOf(msg.sender));

        vm.startPrank(msg.sender);
        engine.burnToken(_amount);
        vm.stopPrank();
    }
}
