// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {LetSwapRouter} from "../src/LetSwapRouter.sol";
import {LetSwapFactory} from "../src/LetSwapFactory.sol";
import {LetSwapPair} from "../src/LetSwapPair.sol";
import {ERC20Mock} from "../src/test/ERC20Mock.sol";
import {MockWETH} from "../src/test/MockWETH.sol";
import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {LetSwapLibrary} from "../src/libraries/LetSwapLibrary.sol";

contract AnvilInteractions is Script {
    LetSwapRouter router = LetSwapRouter(payable(0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0));
    LetSwapFactory factory = LetSwapFactory(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);
    LetSwapPair aavepepe = LetSwapPair(0x838113DA03F09440BAbf45f1E3e9CE63c4748D37);
    LetSwapPair aaveusdc = LetSwapPair(0x67d2A69D389593Ae876E6eD9BBBA7aA656cAF3D2);
    LetSwapPair pepeusdc = LetSwapPair(0xDA528d8B1bA02b63E1863B98F770c0524cC44529);
    ERC20Mock aave = ERC20Mock(0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9);
    ERC20Mock pepe = ERC20Mock(0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9);
    ERC20Mock usdc = ERC20Mock(0x5FC8d32690cc91D4c39d9d3abcBD16989F875707);
    address user = 0x39CA5312eF96cBF09c43ea7F2eAd639c539BF613;
    address wethAddress;
    address feeToSetter;

    function createPairs() public {
        vm.startBroadcast();
        wethAddress = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
        aavepepe = LetSwapPair(factory.createPair(address(aave), address(pepe)));
        aaveusdc = LetSwapPair(factory.createPair(address(aave), address(usdc)));
        pepeusdc = LetSwapPair(factory.createPair(address(pepe), address(usdc)));
        console.log("aavepepe", address(aavepepe));
        console.log("aaveusdc", address(aaveusdc));
        console.log("pepeusdc", address(pepeusdc));
        vm.stopBroadcast();
    }

    function addLiquidity() public {
        vm.startBroadcast();
        aave.approve(address(router), type(uint256).max);
        pepe.approve(address(router), type(uint256).max);
        usdc.approve(address(router), type(uint256).max);

        router.addLiquidity(
            address(aave),
            address(pepe),
            1000 ether,
            100000 ether,
            100 ether,
            100 ether,
            msg.sender,
            block.timestamp + 15 minutes
        );
        router.addLiquidity(
            address(aave),
            address(usdc),
            10000 ether,
            100000 ether,
            100 ether,
            100 ether,
            msg.sender,
            block.timestamp + 15 minutes
        );
        router.addLiquidity(
            address(pepe),
            address(usdc),
            1000000 ether,
            10000 ether,
            100 ether,
            100 ether,
            msg.sender,
            block.timestamp + 15 minutes
        );
        vm.stopBroadcast();
    }

    function checkReserves() public {
        (uint256 reserve0, uint256 reserve1) = aavepepe.getReserves();
        uint256 lpTokenBalance = aavepepe.balanceOf(user);

        console.log("aave Reserve:", reserve0);
        console.log("pepe Reserve:", reserve1);
        console.log("User LP Token Balance:", lpTokenBalance);
        console.log("User aave Balance:", aave.balanceOf(user));
        console.log("User pepe Balance:", pepe.balanceOf(user));
        console.log("User usdc Balance:", usdc.balanceOf(user));
    }

    function removeLiquidity() public {
        vm.startBroadcast();

        router.removeLiquidity(address(aave), address(usdc), 100 ether, 0, 0, user, block.timestamp + 15 minutes);
        vm.stopBroadcast();
    }

    function addLiquidityETH() public {
        vm.startBroadcast();
        router.addLiquidityETH{value: 200 ether}(
            address(aave), 10000 ether, 100 ether, 100 ether, user, block.timestamp + 15 minutes
        );
        router.addLiquidityETH{value: 200 ether}(
            address(pepe), 10000 ether, 100 ether, 100 ether, user, block.timestamp + 15 minutes
        );
        router.addLiquidityETH{value: 200 ether}(
            address(usdc), 10000 ether, 100 ether, 100 ether, user, block.timestamp + 15 minutes
        );
        vm.stopBroadcast();
    }
}

contract InteractionsSepolia is Script {
    LetSwapRouter router = LetSwapRouter(payable(0x6e59b0edbceFfEe637F1dcf84045b9D58af1F494));
    LetSwapFactory factory = LetSwapFactory(0x7acB3A63088ce38ea202203C44611cB7141461d6);
    ERC20Mock aave = ERC20Mock(0xe222CC05D2b26E0cD9b5A48b533c5498bc18156F);
    ERC20Mock pepe = ERC20Mock(0xDFdEF9c862E04a1A9B0f1bA03642fB5Bf6071031);
    ERC20Mock link = ERC20Mock(0xB2dfC378Fa04dB5893154c2f5a6513658648301c);
    ERC20Mock uni = ERC20Mock(0x3B80270514d4354Decd5c56E6d1d93612c28643e);
    ERC20Mock dai = ERC20Mock(0x69D5026d0B0642B144DA006592fEB31732C28472);
    ERC20Mock usdt = ERC20Mock(0xd026e6D09123909585958e50A43EEe4CE5AbCc1B);
    ERC20Mock shib = ERC20Mock(0x62A791df613e921d422fDf9D9D7160Ab2dc1ccEa);
    ERC20Mock ens = ERC20Mock(0x023E834F143F08c4dD3B743B88d573F8B0a18A34);
    ERC20Mock wbtc = ERC20Mock(0x200e17A99eB5D5aFDD75C1743C1a034CE75D73A2);
    ERC20Mock crv = ERC20Mock(0x28954C8cD7109723e52E04e3078F45076a8bBEd6);
    ERC20Mock mkr = ERC20Mock(0x4364d28e9AD1086473462b0782324548280b758F);
    ERC20Mock ape = ERC20Mock(0x2e9a65B95E35a8f7701f183e8715587fCec1085C);
    ERC20Mock comp = ERC20Mock(0xe444db678515096d273CC84c6dDfDF2D39cC6D62);

    address user = 0x39CA5312eF96cBF09c43ea7F2eAd639c539BF613;

    address wethAddress = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9;
    address feeToSetter = 0x39CA5312eF96cBF09c43ea7F2eAd639c539BF613;

    function approveTokens() public {
        vm.startBroadcast();
        aave.approve(address(router), type(uint256).max);
        // pepe.approve(address(router), type(uint256).max);
        // link.approve(address(router), type(uint256).max);
        // uni.approve(address(router), type(uint256).max);
        // dai.approve(address(router), type(uint256).max);
        // usdt.approve(address(router), type(uint256).max);
        // shib.approve(address(router), type(uint256).max);
        // ens.approve(address(router), type(uint256).max);
        // wbtc.approve(address(router), type(uint256).max);
        // crv.approve(address(router), type(uint256).max);
        // mkr.approve(address(router), type(uint256).max);
        // ape.approve(address(router), type(uint256).max);
        // comp.approve(address(router), type(uint256).max);
        vm.stopBroadcast();
    }

    function addLiquidity() public {
        vm.startBroadcast();

        // router.addLiquidity(
        //     address(aave),
        //     address(pepe),
        //     10000 ether,
        //     149807692307 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(aave),
        //     address(link),
        //     10000 ether,
        //     139856 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(aave),
        //     address(uni),
        //     10000 ether,
        //     202600 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(aave),
        //     address(dai),
        //     10000 ether,
        //     1558862 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(aave),
        //     address(usdt),
        //     10000 ether,
        //     1558862 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(aave),
        //     address(shib),
        //     10000 ether,
        //     83763440860 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(aave),
        //     address(ens),
        //     10000 ether,
        //     88926 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(aave),
        //     address(wbtc),
        //     100000 ether,
        //     230 ether,
        //     0 ether,
        //     0 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(aave),
        //     address(crv),
        //     10000 ether,
        //     5994590 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(aave),
        //     address(mkr),
        //     10000 ether,
        //     1211 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(aave),
        //     address(ape),
        //     10000 ether,
        //     2165419 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(aave),
        //     address(comp),
        //     10000 ether,
        //     35462 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(pepe),
        //     address(link),
        //     10692307692 ether,
        //     100000 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(pepe),
        //     address(uni),
        //     73942307692 ether,
        //     100000 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(pepe),
        //     address(dai),
        //     962500000 ether,
        //     100000 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(pepe),
        //     address(usdt),
        //     962500000 ether,
        //     100000 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(pepe),
        //     address(shib),
        //     17884615384 ether,
        //     10000000000 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(pepe),
        //     address(ens),
        //     16884615384 ether,
        //     100000 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(pepe),
        //     address(wbtc),
        //     324899038460 ether,
        //     50 ether,
        //     0 ether,
        //     0 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(pepe),
        //     address(crv),
        //     250944230 ether,
        //     100000 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(pepe),
        //     address(mkr),
        //     1000 ether,
        //     100000 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(pepe),
        //     address(ape),
        //     1243250000000 ether,
        //     100000 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(pepe),
        //     address(comp),
        //     42423076923 ether,
        //     100000 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(link),
        //     address(uni),
        //     10000 ether,
        //     14538 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(link),
        //     address(dai),
        //     10000 ether,
        //     110000 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(link),
        //     address(usdt),
        //     10000 ether,
        //     110000 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(link),
        //     address(shib),
        //     10000 ether,
        //     6021505376 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(link),
        //     address(ens),
        //     10000 ether,
        //     6356 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(link),
        //     address(wbtc),
        //     1000000 ether,
        //     170 ether,
        //     0 ether,
        //     0 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(link),
        //     address(crv),
        //     1000 ether,
        //     100000 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(link),
        //     address(mkr),
        //     23111 ether,
        //     200 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(link),
        //     address(ape),
        //     10000 ether,
        //     154979 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(link),
        //     address(comp),
        //     10000 ether,
        //     2529 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );

        // router.addLiquidity(
        //     address(uni),
        //     address(dai),
        //     10000 ether,
        //     77000 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(uni),
        //     address(usdt),
        //     10000 ether,
        //     77000 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(uni),
        //     address(shib),
        //     10000 ether,
        //     4150537634 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(uni),
        //     address(ens),
        //     100000 ether,
        //     43830 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(uni),
        //     address(wbtc),
        //     1000000 ether,
        //     110 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(uni),
        //     address(crv),
        //     10000 ether,
        //     295016 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(uni),
        //     address(mkr),
        //     100000 ether,
        //     594 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(uni),
        //     address(ape),
        //     10000 ether,
        //     106495 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(uni),
        //     address(comp),
        //     10000 ether,
        //     1840 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(dai),
        //     address(usdt),
        //     100000 ether,
        //     100000 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(dai),
        //     address(shib),
        //     10000 ether,
        //     538172043 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(dai),
        //     address(ens),
        //     100000 ether,
        //     5690 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(dai),
        //     address(wbtc),
        //     1000000 ether,
        //     15 ether,
        //     0 ether,
        //     0 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(dai),
        //     address(crv),
        //     10000 ether,
        //     38274 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(dai),
        //     address(mkr),
        //     1000000 ether,
        //     773 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(dai),
        //     address(ape),
        //     10000 ether,
        //     13828 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(dai),
        //     address(comp),
        //     1000000 ether,
        //     2260 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(usdt),
        //     address(shib),
        //     10000 ether,
        //     538172043 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(usdt),
        //     address(ens),
        //     100000 ether,
        //     5690 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(usdt),
        //     address(wbtc),
        //     1000000 ether,
        //     15 ether,
        //     0 ether,
        //     0 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(usdt),
        //     address(crv),
        //     10000 ether,
        //     38274 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(usdt),
        //     address(mkr),
        //     1000000 ether,
        //     773 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(usdt),
        //     address(ape),
        //     10000 ether,
        //     13828 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(usdt),
        //     address(comp),
        //     1000000 ether,
        //     2260 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        // router.addLiquidity(
        //     address(shib),
        //     address(ens),
        //     9395721925 ether,
        //     10000 ether,
        //     100 ether,
        //     100 ether,
        //     msg.sender,
        //     block.timestamp + 15 minutes
        // );
        router.addLiquidity(
            address(shib),
            address(wbtc),
            17989627659 ether,
            5 ether,
            0 ether,
            0 ether,
            msg.sender,
            block.timestamp + 15 minutes
        );
        router.addLiquidity(
            address(shib),
            address(crv),
            137787234 ether,
            10000 ether,
            100 ether,
            100 ether,
            msg.sender,
            block.timestamp + 15 minutes
        );
        router.addLiquidity(
            address(shib),
            address(mkr),
            685707446808 ether,
            10000 ether,
            100 ether,
            100 ether,
            msg.sender,
            block.timestamp + 15 minutes
        );
        router.addLiquidity(
            address(shib),
            address(ape),
            764268085 ether,
            20000 ether,
            100 ether,
            100 ether,
            msg.sender,
            block.timestamp + 15 minutes
        );
        router.addLiquidity(
            address(shib),
            address(comp),
            23792553191 ether,
            10000 ether,
            100 ether,
            100 ether,
            msg.sender,
            block.timestamp + 15 minutes
        );
        router.addLiquidity(
            address(ens),
            address(wbtc),
            581720 ether,
            150 ether,
            100 ether,
            100 ether,
            msg.sender,
            block.timestamp + 15 minutes
        );
        router.addLiquidity(
            address(ens),
            address(crv),
            1000 ether,
            100000 ether,
            100 ether,
            100 ether,
            msg.sender,
            block.timestamp + 15 minutes
        );
        router.addLiquidity(
            address(ens),
            address(mkr),
            10000 ether,
            672167 ether,
            100 ether,
            100 ether,
            msg.sender,
            block.timestamp + 15 minutes
        );
        router.addLiquidity(
            address(ens),
            address(ape),
            10000 ether,
            242517 ether,
            100 ether,
            100 ether,
            msg.sender,
            block.timestamp + 15 minutes
        );
        router.addLiquidity(
            address(ens),
            address(comp),
            10000 ether,
            3891 ether,
            100 ether,
            100 ether,
            msg.sender,
            block.timestamp + 15 minutes
        );
        router.addLiquidity(
            address(wbtc),
            address(crv),
            380 ether,
            100000000 ether,
            100 ether,
            100 ether,
            msg.sender,
            block.timestamp + 15 minutes
        );
        router.addLiquidity(
            address(wbtc),
            address(mkr),
            120 ether,
            5248 ether,
            100 ether,
            100 ether,
            msg.sender,
            block.timestamp + 15 minutes
        );
        router.addLiquidity(
            address(wbtc),
            address(ape),
            190 ether,
            10000 ether,
            100 ether,
            100 ether,
            msg.sender,
            block.timestamp + 15 minutes
        );
        router.addLiquidity(
            address(wbtc),
            address(comp),
            660 ether,
            1000000 ether,
            100 ether,
            100 ether,
            msg.sender,
            block.timestamp + 15 minutes
        );
        router.addLiquidity(
            address(crv),
            address(mkr),
            10000000 ether,
            2011 ether,
            100 ether,
            100 ether,
            msg.sender,
            block.timestamp + 15 minutes
        );
        router.addLiquidity(
            address(crv),
            address(ape),
            10000 ether,
            3603 ether,
            100 ether,
            100 ether,
            msg.sender,
            block.timestamp + 15 minutes
        );
        router.addLiquidity(
            address(crv),
            address(comp),
            100000 ether,
            579 ether,
            100 ether,
            100 ether,
            msg.sender,
            block.timestamp + 15 minutes
        );
        router.addLiquidity(
            address(mkr),
            address(ape),
            1000 ether,
            1792328 ether,
            100 ether,
            100 ether,
            msg.sender,
            block.timestamp + 15 minutes
        );
        router.addLiquidity(
            address(mkr),
            address(comp),
            1000 ether,
            28817 ether,
            100 ether,
            100 ether,
            msg.sender,
            block.timestamp + 15 minutes
        );
        router.addLiquidity(
            address(ape),
            address(comp),
            100000 ether,
            1607 ether,
            100 ether,
            100 ether,
            msg.sender,
            block.timestamp + 15 minutes
        );

        vm.stopBroadcast();
    }

    function addLiquidityEth() public {
        vm.startBroadcast();
        router.addLiquidityETH{value: 2 ether}(
            address(aave), 33 ether, 0 ether, 0 ether, msg.sender, block.timestamp + 15 minutes
        );
        router.addLiquidityETH{value: 2 ether}(
            address(pepe), 513938000 ether, 0 ether, 0 ether, msg.sender, block.timestamp + 15 minutes
        );
        router.addLiquidityETH{value: 2 ether}(
            address(link), 470 ether, 0 ether, 0 ether, msg.sender, block.timestamp + 15 minutes
        );
        router.addLiquidityETH{value: 2 ether}(
            address(uni), 700 ether, 0 ether, 0 ether, msg.sender, block.timestamp + 15 minutes
        );
        router.addLiquidityETH{value: 2 ether}(
            address(dai), 5000 ether, 0 ether, 0 ether, msg.sender, block.timestamp + 15 minutes
        );
        router.addLiquidityETH{value: 2 ether}(
            address(usdt), 5000 ether, 0 ether, 0 ether, msg.sender, block.timestamp + 15 minutes
        );
        router.addLiquidityETH{value: 2 ether}(
            address(shib), 288857000 ether, 0 ether, 0 ether, msg.sender, block.timestamp + 15 minutes
        );
        router.addLiquidityETH{value: 2 ether}(
            address(ens), 301 ether, 0 ether, 0 ether, msg.sender, block.timestamp + 15 minutes
        );
        router.addLiquidityETH{value: 2 ether}(
            address(wbtc), 0.0777 ether, 0 ether, 0 ether, msg.sender, block.timestamp + 15 minutes
        );
        router.addLiquidityETH{value: 2 ether}(
            address(crv), 20351 ether, 0 ether, 0 ether, msg.sender, block.timestamp + 15 minutes
        );
        router.addLiquidityETH{value: 2 ether}(
            address(mkr), 4 ether, 0 ether, 0 ether, msg.sender, block.timestamp + 15 minutes
        );
        router.addLiquidityETH{value: 2 ether}(
            address(ape), 7232 ether, 0 ether, 0 ether, msg.sender, block.timestamp + 15 minutes
        );
        router.addLiquidityETH{value: 2 ether}(
            address(comp), 114 ether, 0 ether, 0 ether, msg.sender, block.timestamp + 15 minutes
        );
        vm.stopBroadcast();
    }
}
