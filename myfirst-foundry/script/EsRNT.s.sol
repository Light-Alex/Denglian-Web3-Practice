// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./BaseScript.s.sol";
import "../src/EsRNT.sol";

contract EsRNTScript is BaseScript {

    // 部署 esRNT 合约
    function run() public broadcaster {
        esRNT esRNT = new esRNT();
        saveContract("localhost", "esRNT", address(esRNT));
        console.log("esRNT deployed on %s", address(esRNT));
    }
}