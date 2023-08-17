# STABLE COIN CONTROLED BY A GOVERNANCE

This is a simple stable coin contract inspired by PatrickCollins, you can mint stable coin pegget to asset that support chainlink, deposit collateral, reedem, liquidation, this protocol work with chainlink and the backup is gonna be uniswap oracle v3 (no implemented yet).

## Engine contract

Core Contract of the protocol, this contract allow user to deposit collateral, mint the stable coin, get back collateral and liquidate users, this contract can be pegged to whatever asset that support

### Security

This contract count with a test coverage of 80% and some fuzzing passing importans invariants. this contract does not have an audit review.

## Governance contract

Governance contract that control the collaterals tokens and the fee recoleted by the protocool(not implemented yet), this contract is made by wizzard openzzepeling

### security

this contract is full powered by openzzepeling and aditional have a integration test with the protocol.

## Start coding

run `forge build`
run `forge test`
