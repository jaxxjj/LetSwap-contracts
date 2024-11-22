// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {ILetSwapPair} from "../interfaces/ILetSwapPair.sol";
import {ILetSwapFactory} from "../interfaces/ILetSwapFactory.sol";

error LetSwapLibrary__PairAddressMismatch();
error LetSwapLibrary__InsufficientAmount();
error LetSwapLibrary__InsufficientLiquidity();
error LetSwapLibrary__IdenticalAddresses();
error LetSwapLibrary__ZeroAddress();
error LetSwapLibrary__InsufficientInputAmount();
error LetSwapLibrary__InsufficientOutputAmount();
error LetSwapLibrary__InvalidPath();

library LetSwapLibrary {
    /**
     * @notice Returns sorted token addresses
     * @dev Used to handle return values from pairs sorted in this order
     * @param tokenA Address of the first token
     * @param tokenB Address of the second token
     * @return token0 Address of the first token (sorted)
     * @return token1 Address of the second token (sorted)
     */
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        if (tokenA == tokenB) {
            revert LetSwapLibrary__IdenticalAddresses();
        }
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        if (token0 == address(0)) {
            revert LetSwapLibrary__ZeroAddress();
        }
    }

    /**
     * @notice Calculates the CREATE2 address for a pair without making any external calls
     * @param factory Address of the LetSwap factory
     * @param tokenA Address of the first token
     * @param tokenB Address of the second token
     * @return pair Address of the pair
     */
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"cfbe088b416bcbd2f3cf5f03573eb1b6feb1b688542e3d489ab35273bc10237d"
                        )
                    )
                )
            )
        );
    }

    /**
     * @notice Fetches and sorts the reserves for a pair
     * @param factory Address of the LetSwap factory
     * @param tokenA Address of the first token
     * @param tokenB Address of the second token
     * @return reserveA Reserve of the first token
     * @return reserveB Reserve of the second token
     */
    function getReserves(address factory, address tokenA, address tokenB)
        internal
        view
        returns (uint256 reserveA, uint256 reserveB)
    {
        (address token0,) = sortTokens(tokenA, tokenB);
        address calculatedPair = pairFor(factory, tokenA, tokenB);
        address actualPair = ILetSwapFactory(factory).getPair(tokenA, tokenB);
        if (calculatedPair != actualPair) revert LetSwapLibrary__PairAddressMismatch();
        (uint256 reserve0, uint256 reserve1) = ILetSwapPair(calculatedPair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    /**
     * @notice Given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
     * @param amountA Amount of the first asset
     * @param reserveA Reserve of the first asset
     * @param reserveB Reserve of the second asset
     * @return amountB Equivalent amount of the second asset
     */
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
        if (amountA <= 0) {
            revert LetSwapLibrary__InsufficientAmount();
        }
        if (reserveA <= 0 || reserveB <= 0) {
            revert LetSwapLibrary__InsufficientLiquidity();
        }
        amountB = (amountA * reserveB) / reserveA;
    }

    /**
     * @notice Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
     * @param amountIn Input amount of the asset
     * @param reserveIn Reserve of the input asset
     * @param reserveOut Reserve of the output asset
     * @return amountOut Maximum output amount of the other asset
     */
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountOut)
    {
        if (amountIn <= 0) {
            revert LetSwapLibrary__InsufficientInputAmount();
        }
        if (reserveIn <= 0 || reserveOut <= 0) {
            revert LetSwapLibrary__InsufficientLiquidity();
        }
        unchecked {
            uint256 amountInWithFee = amountIn * 997;
            uint256 numerator = amountInWithFee * reserveOut;
            uint256 denominator = reserveIn * 1000 + amountInWithFee;
            amountOut = numerator / denominator;
        }
    }

    /**
     * @notice Given an output amount of an asset and pair reserves, returns a required input amount of the other asset
     * @param amountOut Output amount of the asset
     * @param reserveIn Reserve of the input asset
     * @param reserveOut Reserve of the output asset
     * @return amountIn Required input amount of the other asset
     */
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountIn)
    {
        if (amountOut <= 0) {
            revert LetSwapLibrary__InsufficientOutputAmount();
        }
        if (reserveIn <= 0 || reserveOut <= 0) {
            revert LetSwapLibrary__InsufficientLiquidity();
        }
        unchecked {
            uint256 numerator = reserveIn * amountOut * 1000;
            uint256 denominator = (reserveOut - amountOut) * 997;
            amountIn = numerator / denominator + 1;
        }
    }

    /**
     * @notice Performs chained getAmountOut calculations on any number of pairs
     * @param factory Address of the LetSwap factory
     * @param amountIn Input amount of the asset
     * @param path Array of token addresses
     * @return amounts Array of output amounts for each pair
     */
    function getAmountsOut(address factory, uint256 amountIn, address[] memory path)
        internal
        view
        returns (uint256[] memory amounts)
    {
        uint256 pathLength = path.length;
        if (pathLength < 2) {
            revert LetSwapLibrary__InvalidPath();
        }
        amounts = new uint256[](pathLength);
        amounts[0] = amountIn;
        for (uint256 i; i < pathLength - 1;) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Performs chained getAmountIn calculations on any number of pairs
     * @param factory Address of the LetSwapctory
     * @param amountOut Output amount of the asset
     * @param path Array of token addresses
     * @return amounts Array of input amounts for each pair
     */
    function getAmountsIn(address factory, uint256 amountOut, address[] memory path)
        internal
        view
        returns (uint256[] memory amounts)
    {
        uint256 pathLength = path.length;
        if (pathLength < 2) {
            revert LetSwapLibrary__InvalidPath();
        }
        amounts = new uint256[](pathLength);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = pathLength - 1; i > 0;) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
            unchecked {
                --i;
            }
        }
    }
}
