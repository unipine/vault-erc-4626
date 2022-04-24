# Build a yield strategy with Tribe Turbo and ERC-4626
Tutorial on creating a yield generating strategy using the Tribe DAO's Turbo and ERC-4626 products.
## Getting started
1. Git clone this repo: `git clone https://github.com/fei-protocol/ethAmsterdam-getting-started.git`
2. Install Forge and contract dependencies: `git submodule update --init --recursive`
3. Install developer dependencies: `npm install`
4. Compile contracts: `forge build`
5. Run tests by forking mainnet: `API_KEY=0x123 forge test --fork-url https://eth-mainnet.alchemyapi.io/v2/$API_KEY`

## Prerequisites
Forge installed. To install:
1. `curl -L https://foundry.paradigm.xyz | bash`
2. `foundryup`

## Background
This tutorial relies on three of the Tribe DAO's products:
### ERC-4626
A new standard for Tokenized vaults. It represents a strategy which is itself also tokenised
- https://github.com/fei-protocol/ERC4626
### Turbo
A standard wrapper, called a Safe, around a collaterised Fuse lending position. 

Users create a Safe and then borrow Fei. The borrowed Fei is costless, 0% APR, and that borrowed Fei is programmatically placed into an ERC-4626 strategy.
- https://github.com/fei-protocol/tribe-turbo

### Flywheel V2
Flywheel is generalised token infrastructure to allow rewards to be distributed to an arbitrary strategy. It has a highly modular architecture and is in production on several Fuse pools.
- https://github.com/fei-protocol/flywheel-v2
- https://github.com/fei-protocol/fuse-flywheel 

### Docs
Tribe DAO documentation is at: https://fei-protocol.github.io/docs/ 

## How it works
The tutorial takes you through the end to end flow of creating a strategy, opening a Turbo Safe and generating yield from that safe by deploying into the stragegy.

The steps are:
1. Creating an ERC-4626 strategy, in this tutorial we use Fuse pools as the target
2. Create a Turbo Safe, this is a wrapper around a soon to be collaterised fuse position
3. Deposit collateral into the Turbo Safe
4. Boost from the Turbo Safe into the strategy of your choosing

It uses Forge and Foundry as the smart contract development framework and relies on Mainnet forking to avoid setting up Rari fuse pools etc.


Powered by [forge-template](https://github.com/FrankieIsLost/forge-template)

## ABIs and Mainnet addresses
Commonly required ABIs and mainnet addresses, for use when creating Hardhat based hacks, are available in the `protocolArtifacts/` dir.

