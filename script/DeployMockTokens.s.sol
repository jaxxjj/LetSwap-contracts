// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {ERC20Mock} from "../src/test/ERC20Mock.sol";

contract DeployMockTokens is Script {
    function run() public {
        bytes32 secretKey = vm.envBytes32("ANVIL_PRIVATE_KEY");
        vm.startBroadcast(uint256(secretKey));
        ERC20Mock token0 = new ERC20Mock("Aave", "AAVE", 1000000000 ether);
        ERC20Mock token1 = new ERC20Mock("Pepe Token", "PEPE", 1000000000 ether);
        ERC20Mock token2 = new ERC20Mock("USDCoin", "USDC", 1000000000 ether);

        vm.stopBroadcast();

        console.log("AAVE deployed at:", address(token0));
        console.log("PEPE deployed at:", address(token1));
        console.log("USDC deployed at:", address(token2));
    }
}
