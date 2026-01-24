// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./BaseScript.s.sol";
import "../src/Multicall/Multicall.sol";

contract DeployMuticallScript is BaseScript {

    // 部署 MyNFTMarket 合约
    function run() public broadcaster {
        console.log("Deployer address: %s", deployer);

        // 部署 Multicall 合约
        Multicall multicall = new Multicall();
        saveContract(getNetworkName(block.chainid), "Multicall", address(multicall));
        console.log("Multicall deployed on %s", address(multicall));
    }
}