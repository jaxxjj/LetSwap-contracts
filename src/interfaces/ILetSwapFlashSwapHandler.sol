// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

// @notice Interface for contracts that want to handle flash swap callbacks from Uniswap V2 pair contracts

interface ILetSwapFlashSwapHandler {
    /**
     * @notice Called by a Uniswap V2 pair contract after a flash swap is initiated
     * @dev Implement this function to handle the logic for the flash swap, such as arbitrage or liquidation
     * @param sender The address that initiated the flash swap
     * @param amount0 The amount of token0 that was borrowed
     * @param amount1 The amount of token1 that was borrowed
     * @param data Additional data passed to the function, which can be used to encode any extra information needed for the logic
     */
    function letSwapFlashSwap(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external;
}
