// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {ERC20Mock} from "../src/test/ERC20Mock.sol";

contract DeployMockTokens is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        ERC20Mock token0 = new ERC20Mock("SHIBA INU", "SHIB", 100000000000000000000000 ether);

        vm.stopBroadcast();

        console.log("MKR deployed at:", address(token0));
    }
}
