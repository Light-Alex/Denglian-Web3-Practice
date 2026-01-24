// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "./BaseScript.s.sol";
import "../src/MyTokenPermit.sol";
import {SimpleNFTV1} from "../src/SimpleNFTV1.sol";
import {NFTMarketV1} from "../src/NFTMarketV1.sol";
import { Upgrades, Options } from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployNFTMarketScript is BaseScript {
    function run() public broadcaster {
        // Deploy MyTokenPermit with 1 million initial supply (18 decimals)
        MyTokenPermit token = new MyTokenPermit(10000);
        saveContract(getNetworkName(block.chainid), "MyTokenPermit", address(token));

        // 设置代理部署选项
        Options memory opts;

        // 跳过所有安全检查
        opts.unsafeSkipAllChecks = true;

        // 部署透明代理合约
        address nftProxy = Upgrades.deployTransparentProxy(
            "SimpleNFTV1.sol:SimpleNFTV1",  // 逻辑合约名称（指定合约名称以避免歧义）
            deployer,           // ProxyAdmin 的 owner 地址
            abi.encodeCall(SimpleNFTV1.initialize, ("SimpleNFT", "SNFT")),  // 初始化参数
            opts                // 部署选项
        );
        saveContract(getNetworkName(block.chainid), "SimpleNFTV1", address(nftProxy));

        address nftMarketProxy = Upgrades.deployTransparentProxy(
            "NFTMarketV1.sol:NFTMarketV1",  // 逻辑合约名称（指定合约名称以避免歧义）
            deployer,           // ProxyAdmin 的 owner 地址
            abi.encodeCall(NFTMarketV1.initialize, (address(token))),  // 初始化参数
            opts                // 部署选项
        );
        saveContract(getNetworkName(block.chainid), "NFTMarketV1", address(nftMarketProxy));

        console.log("\n=== Deployment Complete ===");
        console.log("Deployer address: ", deployer);
        console.log("MyTokenPermit:", address(token));
        console.log("NFT Proxy:", address(nftProxy));
        console.log("NFTMarket Proxy:", address(nftMarketProxy));
    }
}
