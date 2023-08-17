// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {DaoToken} from "../contracts/governans/DaoToken.sol";
import {TimeLocker} from "../contracts/governans/TimeLocker.sol";
import {GovernorDao} from "../contracts/governans/GovernorDao.sol";

import {Engine} from "../contracts/Engine.sol";

import {MockV3Aggregator} from "../test/Mocks/MockV3Aggregator.sol";
import {ERC20Mock} from "openzeppelin/mocks/ERC20Mock.sol";

contract GovernanTest is Test {
    DaoToken public daoToken;
    TimeLocker public timeLocker;
    GovernorDao public governorDao;
    Engine public engine;

    address public ethUsdPriceFeed;
    address public weth;

    uint256 public mintDelay = 2 days;

    address public user_one = vm.addr(1);
    address public user_two = vm.addr(2);

    address[] public zero_array;

    address[] public targets;
    uint256[] public values;
    bytes[] public calldatas;
    string public description;

    function setUp() public {
        weth = (address(new ERC20Mock()));
        ethUsdPriceFeed = (address(new MockV3Aggregator(8, 2000e8)));

        daoToken = new DaoToken(user_one);

        timeLocker = new TimeLocker(mintDelay, zero_array, zero_array, address(this));
        governorDao = new GovernorDao(daoToken, timeLocker);
        vm.prank(user_one);
        daoToken.delegate(user_one);

        bytes32 TIMELOCK_ADMIN_ROLE = keccak256("TIMELOCK_ADMIN_ROLE");
        bytes32 PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
        bytes32 EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

        timeLocker.grantRole(PROPOSER_ROLE, address(governorDao));
        timeLocker.grantRole(EXECUTOR_ROLE, address(0));
        timeLocker.revokeRole(TIMELOCK_ADMIN_ROLE, address(this));

        engine = new Engine(zero_array, zero_array);
        engine.transferOwnership(address(timeLocker));
    }

    function testOwner() public {
        address ownerEngine = engine.owner();
        assert(ownerEngine == address(timeLocker));
    }

    function testProposal() public {
        //propose a proposal
        targets.push(address(engine));
        values.push(0);
        calldatas.push(abi.encodeWithSelector(bytes4(engine.addTokenAndPriceFeed.selector), weth, ethUsdPriceFeed));
        description = "demo";

        vm.warp(block.timestamp + 7200 + 1);
        vm.roll(block.number + 1);

        vm.prank(user_one);
        uint256 proposalId = governorDao.propose(targets, values, calldatas, description);

        vm.warp(block.timestamp + 7200 + 2);
        vm.roll(block.number + 7200 + 2);

        //quote

        //vote
        vm.prank(user_one);
        governorDao.castVote(proposalId, 1);

        vm.warp(block.timestamp + 50400 + 1);
        vm.roll(block.number + 50400 + 1);

        //queue

        governorDao.queue(proposalId);

        vm.warp(block.timestamp + mintDelay + 1);
        vm.roll(block.number + mintDelay + 1);

        //execute

        bytes32 descriptionHash = keccak256(abi.encodePacked(description));

        governorDao.execute(targets, values, calldatas, descriptionHash);

        address[] memory token = engine.getToken();

        assert(token[0] == weth);
    }
}
