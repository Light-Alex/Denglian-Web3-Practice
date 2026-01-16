// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "./BaseScript.s.sol";

import { Upgrades, Options } from "openzeppelin-foundry-upgrades/Upgrades.sol";


contract CounterScript is BaseScript {
    

    function run() public broadcaster {

        Options memory opts;
        opts.unsafeSkipAllChecks = true;           // 跳过所有安全检查
        opts.referenceContract = "CounterV1.sol";  // 设置参考合约

        // proxy: 0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1
        Upgrades.upgradeProxy(
            0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1,  // 代理合约地址
            "CounterV2.sol",                             // 新实现合约
            "",                                          // 初始化参数
            opts                                         // 部署选项
        );
    }
}