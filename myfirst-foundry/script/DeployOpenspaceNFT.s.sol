// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./BaseScript.s.sol";
import "../src/OpenSpaceNFT.sol";

contract DeployOpenspaceNFT is BaseScript {

    // 部署 OpenspaceNFT 合约
    function run() public broadcaster {
        OpenspaceNFT nft = new OpenspaceNFT();
        saveContract(getNetworkName(block.chainid), "OpenspaceNFT", address(nft));
        console.log("OpenspaceNFT deployed on %s", address(nft));
    }
}