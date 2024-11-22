// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/// @title TransferHelper
/// @notice A library for safe token transfers and approvals
library TransferHelper {
    error TransferHelper__ApproveFailed();
    error TransferHelper__TransferFailed();
    error TransferHelper__TransferFromFailed();
    error TransferHelper__ETHTransferFailed();

    /// @notice Safely approves the transfer of tokens
    /// @param token The address of the ERC20 token
    /// @param to The address that will be approved to spend the tokens
    /// @param value The amount of tokens to approve
    function safeApprove(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        if (!success || (data.length != 0 && !_checkReturnValue(data))) {
            revert TransferHelper__ApproveFailed();
        }
    }
    /// @notice Safely transfers tokens
    /// @param token The address of the ERC20 token
    /// @param to The address that will receive the tokens
    /// @param value The amount of tokens to transfer

    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        if (!success || (data.length != 0 && !_checkReturnValue(data))) {
            revert TransferHelper__TransferFailed();
        }
    }
    /// @notice Safely transfers tokens from one address to another
    /// @param token The address of the ERC20 token
    /// @param from The address to transfer tokens from
    /// @param to The address to transfer tokens to
    /// @param value The amount of tokens to transfer

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        if (!success || (data.length != 0 && !_checkReturnValue(data))) {
            revert TransferHelper__TransferFromFailed();
        }
    }
    /// @notice Safely transfers ETH
    /// @param to The address that will receive the ETH
    /// @param value The amount of ETH to transfer

    function safeTransferETH(address to, uint256 value) internal {
        (bool success,) = to.call{value: value}("");
        if (!success) {
            revert TransferHelper__ETHTransferFailed();
        }
    }
    /// @notice Checks the return value of a token operation
    /// @dev This function is used internally to verify the success of token operations
    /// @param data The return data from the token operation
    /// @return result True if the operation was successful, false otherwise

    function _checkReturnValue(bytes memory data) private pure returns (bool) {
        bool result;
        assembly {
            let len := mload(data)
            let value := mload(add(data, 32))
            result := and(eq(len, 32), iszero(iszero(value)))
        }
        return result;
    }
}
