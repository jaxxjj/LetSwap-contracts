// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {LetSwapFactory} from "../src/LetSwapFactory.sol";
import {LetSwapRouter} from "../src/LetSwapRouter.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployLetSwap is Script {
    function run() external {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address feeToSetter = config.feeToSetter;
        LetSwapFactory factory = new LetSwapFactory(feeToSetter);
        LetSwapRouter router = new LetSwapRouter(address(factory), config.wethAddress);
        vm.stopBroadcast();

        console.log("LetSwapFactory deployed at:", address(factory));
        console.log("LetSwapRouter deployed at:", address(router));
        console.log("WETH9 deployed at:", config.wethAddress);
    }
}
