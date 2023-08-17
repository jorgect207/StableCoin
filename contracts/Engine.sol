// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title Engine of the protocol
 *
 *
 * @author jorgect
 * @notice this contract govern the whole protocol, you can mint stable coin, deposit collateral, reedem, liquidation, this protocol will be governable to set up the collateral token
 * The principle oracle will be chainlink and the backup is gonna be uniswap oracle v3
 * @this contract its gonna have flash loan too to generate some extra evenue
 */

import "openzeppelin/access/Ownable.sol";
import "openzeppelin/security/ReentrancyGuard.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "./StableCoinToken.sol";
import "chainlink-brownie-contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Engine is Ownable, ReentrancyGuard {
    //errors

    error NON_ZERO_VALUE();
    error NO_TOKEN();
    error NO_LENGTH();
    error NO_BALANCE(uint256 balanceUser);
    error NO_ENOUGHT_COLLATERAL();
    error NO_MINT();
    error NO_ENOUGH_STABLE();
    error GOOD_HEALTH_fACTOR();
    error NO_ENOUGHT_COLLATERL();
    error NO_ENOUGH_USD_TO_LIDUIDATE();
    error TOKEN_ALREADY();

    //state variables

    StableCoinToken public stableCoin;

    uint256 public constant TRESHOLD = 50;
    uint256 public constant TRESHOLD_PRECCISION = 100;

    uint256 public constant DISCOUNT_LIQUIDATION = 900;
    uint256 public constant DISCOUNT_LIQUIDATION_PRECISION = 1000;

    mapping(address user => uint256 minted) public mintedStable;

    mapping(address user => mapping(address tokent => uint256 amount)) public balanceCollateral;

    mapping(address _token => address priceFeed) public priceFeedPar;

    address[] public token;

    //event
    event depositCollateralEvent(address _token, uint256 _amount);
    event removeCollateral(address _token, uint256 _amount);
    event mint(address user, uint256 _amount);
    event burn(address user, uint256 _amount);

    //modifiers

    modifier notZeroValue(uint256 _amount) {
        if (_amount == 0) {
            revert NON_ZERO_VALUE();
        }
        _;
    }

    modifier noToken(address _token) {
        if (priceFeedPar[_token] == address(0)) {
            revert NO_TOKEN();
        }
        _;
    }

    //constructor

    constructor(address[] memory _token, address[] memory _priceFeed) payable {
        uint256 length = _token.length;
        if (length != _priceFeed.length) {
            revert NO_LENGTH();
        }

        for (uint256 i; i < length;) {
            priceFeedPar[_token[i]] = _priceFeed[i];
            token.push(_token[i]);

            unchecked {
                ++i;
            }
        }

        stableCoin = new StableCoinToken();
    }

    //library
    using SafeERC20 for IERC20;

    //external functions

    function depositCollateralAndMintToken(address _token, uint256 _amount, uint256 _amountToMint) external {
        depositCollateral(_token, _amount);
        mintToken(_amountToMint);
        // balanceCollateral[msg.sender][_token] += _amount;
        // emit depositCollateralEvent(_token, _amount);
        // mintedStable[msg.sender] += _amount;
        // bool succes = stableCoin.mint(_amountToMint, msg.sender);
        // if (!succes) {
        //     revert NO_MINT();
        // }
        // IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        // _revertIfHealthFactor(msg.sender);
        // emit mint(msg.sender, _amount);
    }

    /**
     * @notice deposit collateral of whatever is the underlaying asset in the project
     * @param _token token to deposit collateral
     * @param _amount amount of token to deposit
     */

    function depositCollateral(address _token, uint256 _amount) public notZeroValue(_amount) noToken(_token) {
        balanceCollateral[msg.sender][_token] += _amount;
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        emit depositCollateralEvent(_token, _amount);
    }

    /**
     *
     * @param _token token to deposit collateral
     * @param _amount amount of token to deposit
     */
    function redeemCollateral(address _token, uint256 _amount) public notZeroValue(_amount) {
        _redeemCollateral(msg.sender, msg.sender, _token, _amount);
    }

    function redeemCollateralForToken(uint256 _amountStable, address _token, uint256 _amountCollateral) external {
        burnToken(_amountStable);

        _redeemCollateral(msg.sender, msg.sender, _token, _amountCollateral);
    }

    function burnToken(uint256 _amount) public {
        _burnToken(msg.sender, _amount);
    }

    function mintToken(uint256 _amount) public notZeroValue(_amount) {
        mintedStable[msg.sender] += _amount;
        bool succes = stableCoin.mint(_amount, msg.sender);
        if (!succes) {
            revert NO_MINT();
        }
        _revertIfHealthFactor(msg.sender);
        emit mint(msg.sender, _amount);
    }

    /**
     * @notice this function allow a liquidator to liquidate the user with bad heaclfactor
     * @param _collateralAddress the collateral address to liquidate
     * @param _amountToPayUsd the amount to liquidate
     * @param _userToLiquidate the user to liquidate
     */
    function liquidateAll(address _collateralAddress, address _userToLiquidate, uint256 _amountToPayUsd) external {
        uint256 healthFactor = _getHealthFactor(_userToLiquidate);
        if (healthFactor > 1) {
            revert GOOD_HEALTH_fACTOR();
        }
        uint256 mintedStableUser = mintedStable[_userToLiquidate];

        if (_amountToPayUsd < mintedStableUser) {
            revert NO_ENOUGH_USD_TO_LIDUIDATE();
        }

        if (_amountToPayUsd > mintedStableUser) {
            _amountToPayUsd = mintedStableUser;
            // collateral = collateralUser;
        }

        _burnToken(_userToLiquidate, mintedStable[_userToLiquidate]);

        uint256 lenght = token.length;
        uint256 collateralUser;
        for (uint256 i; i < lenght;) {
            collateralUser = balanceCollateral[_userToLiquidate][_collateralAddress];
            if (collateralUser != 0) {
                _redeemCollateral(_userToLiquidate, msg.sender, token[i], collateralUser);
            }

            unchecked {
                ++i;
            }
        }
    }

    function liquidationParcial() external {}

    function addTokenAndPriceFeed(address _token, address _priceFeed) external onlyOwner {
        if (priceFeedPar[_token] == _priceFeed) {
            revert TOKEN_ALREADY();
        }
        token.push(_token);
        priceFeedPar[_token] != _priceFeed;
    }

    function removeTokenAndPriceFeed(address _token) external onlyOwner noToken(_token) {
        delete priceFeedPar[_token];
        uint256 length = token.length;
        for (uint256 i; i < length;) {
            if (token[i] == _token) {
                token[i] == token[length - 1];
                token.pop();
                break;
            }

            unchecked {
                ++i;
            }
        }
    }

    //public functions//

    /**
     * @notice this function is calculating the value of the token to usd
     * @param _token token to convert to usd
     * @param _amount amount to convert to usd
     * @return usdValue Usd value of the amount
     */
    function getPirceUsd(address _token, uint256 _amount) public view noToken(_token) returns (uint256 usdValue) {
        address priceFeedAddress = priceFeedPar[_token];
        AggregatorV3Interface priceFeedParser = AggregatorV3Interface(priceFeedAddress); // the contract its no checking for decimals yet, its working just with 10^8
        (, int256 price,,,) = priceFeedParser.latestRoundData(); // the contract need more validation in the chainlink pricefeed
        usdValue = uint256(price) * 10e10 * _amount / 10e18;
    }

    /**
     *
     * @notice this function is calculating the value of the usd to token
     * @param _token token to get
     * @param _amountUsdInWei amount of usd to convert
     * @return collateralValue value of the usd  amount
     */
    function getPriceCollaterall(address _token, uint256 _amountUsdInWei)
        public
        view
        noToken(_token)
        returns (uint256 collateralValue)
    {
        address priceFeedAddress = priceFeedPar[_token];
        AggregatorV3Interface priceFeedParser = AggregatorV3Interface(priceFeedAddress); // the contract its no checking for decimals yet, its working just with 10^8
        (, int256 price,,,) = priceFeedParser.latestRoundData(); // the contract need more validation in the chainlink pricefeed
        collateralValue = _amountUsdInWei * 10e18 / (uint256(price) * 10e10);
    }

    //internal functions

    /**
     * @notice this function is getting all the collateral value in usd looping through all the tokens in the protocol
     * @param user user to check the all collateral
     * @return AllCollateralInUsd value of the sum of all the different collateral in usd value
     */
    function _getAllCollateralInUsd(address user) internal view returns (uint256 AllCollateralInUsd) {
        uint256 length = token.length;
        for (uint256 i = 0; i < length;) {
            address tokenAddress = token[i];
            uint256 amount = balanceCollateral[user][tokenAddress];
            uint256 amountInUsd = getPirceUsd(tokenAddress, amount);
            AllCollateralInUsd += amountInUsd;
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice
     * @param user
     * @return
     */
    function _getHealthFactor(address user) internal view returns (uint256) {
        uint256 stableMinted = mintedStable[user]; //2000e18
        if (stableMinted == 0) {
            return 1;
        }
        uint256 allCollateralUsd = _getAllCollateralInUsd(user);
        uint256 allCollateralWithTreshols = allCollateralUsd * TRESHOLD / TRESHOLD_PRECCISION;
        return (allCollateralWithTreshols / stableMinted);
    }

    function _revertIfHealthFactor(address user) internal view {
        uint256 healthFactor = _getHealthFactor(user);
        if (healthFactor < 1) {
            revert NO_ENOUGHT_COLLATERAL();
        }
    }

    function _burnToken(address user, uint256 _amount) internal {
        // if (_amount > mintedStable[msg.sender]) {
        //     revert NO_ENOUGH_STABLE();
        // }
        mintedStable[user] -= _amount;
        IERC20(stableCoin).safeTransferFrom(msg.sender, address(this), _amount);
        stableCoin.burn(_amount);
        emit burn(msg.sender, _amount);
    }

    function _redeemCollateral(address _ownerOfCollateral, address _onBehalf, address _token, uint256 _amount)
        internal
        notZeroValue(_amount)
    {
        // uint256 balanceUser = balanceCollateral[msg.sender][_token];
        // if (balanceUser < _amount) {
        //     revert NO_BALANCE(balanceUser);
        // }
        balanceCollateral[_ownerOfCollateral][_token] -= _amount;

        if (_ownerOfCollateral == _onBehalf) {
            IERC20(_token).safeTransfer(_onBehalf, _amount);
        } else {
            IERC20(_token).safeTransfer(_onBehalf, _amount * DISCOUNT_LIQUIDATION / DISCOUNT_LIQUIDATION_PRECISION);
            //we got it keep the other 0.1 collateral
        }

        emit removeCollateral(_token, _amount);

        _revertIfHealthFactor(_ownerOfCollateral);
    }

    function _getAllCollateralToken(address user) internal view returns (uint256[] memory _amounts) {
        uint256 length = token.length;
        _amounts = new uint256[](length);
        for (uint256 i = 0; i < length;) {
            address tokenAddress = token[i];
            _amounts[i] = (balanceCollateral[user][tokenAddress]);
        }
    }
    //view function

    function getBalanceCollateralUser(address _user, address _token) external view returns (uint256) {
        return balanceCollateral[_user][_token];
    }

    function getHealthFactor(address user) external view returns (uint256 health) {
        health = _getHealthFactor(user);
    }

    function getToken() external view returns (address[] memory _token) {
        _token = token;
    }

    function getPriceFeed() external view returns (address[] memory pricefeed) {
        uint256 tokenLenght = token.length;
        pricefeed = new address[](token.length);
        for (uint256 i; i < tokenLenght;) {
            pricefeed[i] = (priceFeedPar[token[i]]);

            unchecked {
                ++i;
            }
        }
    }
}
