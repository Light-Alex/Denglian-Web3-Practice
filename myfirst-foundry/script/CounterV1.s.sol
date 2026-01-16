// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "./BaseScript.s.sol";

import { Upgrades, Options } from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract CounterScript is BaseScript {
    

    function run() public broadcaster {

        // 设置代理部署选项
        Options memory opts;

        // 跳过所有安全检查
        opts.unsafeSkipAllChecks = true;

        // 部署透明代理合约
        address proxy = Upgrades.deployTransparentProxy(
            "CounterV1.sol",  // 逻辑合约名称
            deployer,         // INITIAL_OWNER_ADDRESS_FOR_PROXY_ADMIN（代理管理员地址）,
            "",               // abi.encodeCall(MyContract.initialize, ("arguments for the initialize function")  初始化参数（空表示不初始化）
            opts              // 部署选项
            );

        saveContract(getNetworkName(block.chainid), "Counter", proxy);
        console.log("Counter deployed on %s", address(proxy));
    }
}