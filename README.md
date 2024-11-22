# LetSwap Protocol

A gas-optimized fork of Uniswap V2 upgraded to Solidity 0.8.20, featuring enhanced security measures and improved efficiency.

## Overview

LetSwap is a decentralized exchange protocol that builds upon Uniswap V2's proven architecture while introducing improvements:

- Upgraded to Solidity 0.8.20
- Optimized gas consumption
- Enhanced security features
- Full ERC20/ETH swap support
- Automated market making
- Flash swap capability
- Price oracle functionality

## Core Contracts

### LetSwapFactory

- Creates and manages trading pairs
- Deploys new pair contracts
- Maintains pair registry

### LetSwapRouter

- Handles all swap operations
- Manages liquidity addition/removal
- Provides quote calculations

### LetSwapPair

- Implements AMM logic
- Manages pair reserves
- Handles flash swaps
- Provides price data

### LetSwapLibrary

- Core calculations
- Helper functions
- Safety checks

## Gas Optimizations

| Operation          | Average Gas |
| ------------------ | ----------- |
| Add Liquidity      | ~260,000    |
| Remove Liquidity   | ~111,000    |
| Token Swap         | ~100,000    |
| Factory Deployment | ~1.9M       |

## Usage Examples

### Adding Liquidity

```solidity
// Approve tokens first
IERC20(tokenA).approve(address(router), amountA);
IERC20(tokenB).approve(address(router), amountB);

// Add liquidity
router.addLiquidity(
    tokenA,
    tokenB,
    amountADesired,
    amountBDesired,
    amountAMin,
    amountBMin,
    recipient,
    deadline
);
```
