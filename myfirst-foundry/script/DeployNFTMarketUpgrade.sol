// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "./BaseScript.s.sol";
import "../src/MyTokenPermit.sol";
import {SimpleNFTV2} from "../src/SimpleNFTV2.sol";
import {NFTMarketV2} from "../src/NFTMarketV2.sol";
import { Upgrades, Options } from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployNFTMarketScript is BaseScript {
    function run() public broadcaster {
        Options memory nftOpts;
        nftOpts.unsafeSkipAllChecks = true;           // 跳过所有安全检查
        nftOpts.referenceContract = "SimpleNFTV1.sol:SimpleNFTV1";  // 设置参考合约

        // proxy: 0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82
        // 升级后调用 reinitialize 初始化 _DOMAIN_SEPARATOR
        Upgrades.upgradeProxy(
            0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82,   // 代理合约地址
            "SimpleNFTV2.sol:SimpleNFTV2",                // 新实现合约
            abi.encodeCall(SimpleNFTV2.reinitialize, ()), // 调用 reinitialize 初始化 EIP712
            nftOpts                                       // 部署选项
        );

        Options memory nftMarketOpts;
        nftMarketOpts.unsafeSkipAllChecks = true;           // 跳过所有安全检查
        nftMarketOpts.referenceContract = "NFTMarketV1.sol:NFTMarketV1";  // 设置参考合约

        // proxy: 0x0B306BF915C4d645ff596e518fAf3F9669b97016
        Upgrades.upgradeProxy(
            0x0B306BF915C4d645ff596e518fAf3F9669b97016,  // 代理合约地址
            "NFTMarketV2.sol:NFTMarketV2",               // 新实现合约
            "",                                          // 初始化参数
            nftMarketOpts                                // 部署选项
        );
    }
}
