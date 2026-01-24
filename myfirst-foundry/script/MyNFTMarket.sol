// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./BaseScript.s.sol";
import "../src/MyERC20.sol";
import "../src/MyERC721.sol";
import "../src/NFTMarket.sol";

contract MyNFTMarketScript is BaseScript {

    // 部署 MyNFTMarket 合约
    function run() public broadcaster {
        console.log("Deployer address: %s", deployer);

        // 部署 MyERC20 合约
        MyToken token = new MyToken("MyToken", "MTK");
        saveContract("localhost", "MyToken", address(token));
        console.log("MyToken deployed on %s", address(token));

        // 部署 MyNFT 合约
        MyERC721 nft = new MyERC721();
        saveContract("localhost", "MyERC721", address(nft));
        console.log("MyERC721 deployed on %s", address(nft));

        // 部署 MyNFTMarket 合约
        NFTMarket market = new NFTMarket(address(token), address(nft));
        saveContract("localhost", "NFTMarket", address(market));
        console.log("NFTMarket deployed on %s", address(market));
    }
}