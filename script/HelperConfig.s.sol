// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {MockWETH} from "../src/test/MockWETH.sol";

abstract contract CodeConstants {
    uint256 public constant SEPOLIA_CHAINID = 11155111;
    uint256 public constant LOCAL_CHAINID = 31337;
}

contract HelperConfig is Script, CodeConstants {
    struct NetworkConfig {
        address wethAddress;
        address feeToSetter;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 => NetworkConfig) public chainIdToConfig;

    constructor() {
        chainIdToConfig[SEPOLIA_CHAINID] = getSepoliaConfig();
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (chainId == LOCAL_CHAINID) {
            return getAnvilConfig();
        } else if (chainIdToConfig[chainId].wethAddress != address(0)) {
            return chainIdToConfig[chainId];
        }
        revert("Unsupported chainId");
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        vm.startBroadcast();
        MockWETH weth = new MockWETH();
        vm.stopBroadcast();
        return NetworkConfig({wethAddress: address(weth), feeToSetter: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266});
    }

    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            wethAddress: 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9,
            feeToSetter: 0x39CA5312eF96cBF09c43ea7F2eAd639c539BF613
        });
    }
}
