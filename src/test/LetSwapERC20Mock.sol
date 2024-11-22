// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {LetSwapERC20} from "../LetSwapERC20.sol";

contract ERC20 is LetSwapERC20 {
    constructor(uint256 _totalSupply) {
        _mint(msg.sender, _totalSupply);
    }
}
