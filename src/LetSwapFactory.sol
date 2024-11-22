// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {ILetSwapFactory} from "./interfaces/ILetSwapFactory.sol";
import {ILetSwapPair} from "./interfaces/ILetSwapPair.sol";
import {LetSwapPair} from "./LetSwapPair.sol";

error LetSwapFactory__IdenticalAddresses();
error LetSwapFactory__ZeroAddress();
error LetSwapFactory__PairExists();
error LetSwapFactory__Forbidden();

/// @title LetSwapFactory
/// @notice This contract is used to create and manage LetSwap pairs
contract LetSwapFactory is ILetSwapFactory {
    bytes32 public constant PAIR_HASH = keccak256(type(LetSwapPair).creationCode);

    address public override feeTo;

    address public override feeToSetter;

    mapping(address => mapping(address => address)) public override getPair;

    address[] public override allPairs;

    /// @notice Constructor to set the feeToSetter address
    /// @param _feeToSetter The address that can set the feeTo address
    constructor(address _feeToSetter) payable {
        feeToSetter = _feeToSetter;
    }

    /// @notice Returns the length of the allPairs array
    /// @return The number of pairs created
    function allPairsLength() external view override returns (uint256) {
        return allPairs.length;
    }

    /// @notice Creates a new pair for the given tokens
    /// @param tokenA The address of the first token
    /// @param tokenB The address of the second token
    /// @return pair The address of the created pair
    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        if (tokenA == tokenB) {
            revert LetSwapFactory__IdenticalAddresses();
        }
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        if (token0 == address(0)) {
            revert LetSwapFactory__ZeroAddress();
        }
        if (getPair[token0][token1] != address(0)) {
            revert LetSwapFactory__PairExists();
        }

        pair = address(new LetSwapPair{salt: keccak256(abi.encodePacked(token0, token1))}());
        ILetSwapPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    /// @notice Sets the feeTo address
    /// @param _feeTo The address to which fees will be sent
    function setFeeTo(address _feeTo) external override {
        if (msg.sender != feeToSetter) {
            revert LetSwapFactory__Forbidden();
        }
        feeTo = _feeTo;
    }

    /// @notice Sets the feeToSetter address
    /// @param _feeToSetter The address that can set the feeTo address
    function setFeeToSetter(address _feeToSetter) external override {
        if (msg.sender != feeToSetter) {
            revert LetSwapFactory__Forbidden();
        }
        feeToSetter = _feeToSetter;
    }
}
