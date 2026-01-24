// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./BaseScript.s.sol";
import "../src/WETH9/WETH9.sol";
import "../src/v2-periphery/UniswapV2Router02.sol";

contract DeployRouter02Script is BaseScript {

    // 部署 MyNFTMarket 合约
    function run() public broadcaster {
        console.log("Deployer address: %s", deployer);

        // 部署WETH合约
        WETH9 weth = new WETH9();
        saveContract(getNetworkName(block.chainid), "WETH", address(weth));
        console.log("WETH deployed on %s", address(weth));

        // 部署 UniswapV2Router02 合约
        // 需要手动更改factory合约地址
        UniswapV2Router02 router = new UniswapV2Router02(0xB14A5d0B40D51ec0A45fB4599519aD19Ae826661, address(weth));
        saveContract(getNetworkName(block.chainid), "UniswapV2Router02", address(router));
        console.log("UniswapV2Router02 deployed on %s", address(router));
    }
}