// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./BaseScript.s.sol";
import "../src/v2-core/UniswapV2Factory.sol";

contract DeployFactoryScript is BaseScript {

    // 部署 MyNFTMarket 合约
    function run() public broadcaster {
        console.log("Deployer address: %s", deployer);

        // 部署 UniswapV2Factory 合约
        UniswapV2Factory factory = new UniswapV2Factory(deployer);
        saveContract(getNetworkName(block.chainid), "UniswapV2Factory", address(factory));
        console.log("UniswapV2Factory deployed on %s", address(factory));
    }
}