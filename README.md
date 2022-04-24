# Flat Perp

Democratized access to flat power perps via a composable, tokenized vault standard.

# How it works

Flat Perp alternates between two different Power Perp strategies!

_Vault States_

- Vault is below 6.9 ETH: Funds go into the Euler strategy
- Vault is above 6.9 ETH: Funds go into the Power strategy

### Euler Vault

(Deposit ETH -> Borrow oSQTH -> Short oSQTH)

### Power Vault

(Withdraw ETH -> Swap to oSQTH -> Repay oSQTH Loan -> Take out ETH Profit)

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

FlatPerp is built on top of three products: ERC4626, Squeeth & Euler!

### ERC-4626

A new standard for Tokenized vaults. It represents a strategy which is itself also tokenised

- https://github.com/fei-protocol/ERC4626

### Squeeth

- https://squeeth.opyn.co/

### Euler

- https://app.euler.finance/

## ABIs and Mainnet addresses

Commonly required ABIs and mainnet addresses, for use when creating Hardhat based hacks, are available in the `protocolArtifacts/` dir.
