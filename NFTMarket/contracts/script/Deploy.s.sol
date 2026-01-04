// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/BaseERC20.sol";
import "../src/MyTokenPermit.sol";
import "../src/MyNFTPermit.sol";
import "../src/NFTMarket.sol";
import "../src/SimpleNFT.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // // Deploy BaseERC20 token with 1 million initial supply (18 decimals)
        // BaseERC20 token = new BaseERC20("Market Token", "MTK", 1_000_000 * 10**18);
        // console.log("BaseERC20 deployed at:", address(token));
        // saveContract(getNetworkName(block.chainid), "BaseERC20", address(token));

        // Deploy MyTokenPermit with 1 million initial supply (18 decimals)
        MyTokenPermit token = new MyTokenPermit(10000);
        console.log("MyTokenPermit deployed at:", address(token));
        saveContract(getNetworkName(block.chainid), "MyTokenPermit", address(token));

        // // Deploy SimpleNFT
        // SimpleNFT simpleNFT = new SimpleNFT();
        // console.log("SimpleNFT deployed at:", address(simpleNFT));
        // saveContract(getNetworkName(block.chainid), "SimpleNFT", address(simpleNFT));

        MyNFTPermit myNFT = new MyNFTPermit();
        console.log("MyNFTPermit deployed at:", address(myNFT));
        saveContract(getNetworkName(block.chainid), "MyNFTPermit", address(myNFT));

        // Deploy NFTMarket with token address
        NFTMarket nftMarket = new NFTMarket(address(token), address(vm.addr(deployerPrivateKey)));
        console.log("NFTMarket deployed at:", address(nftMarket));
        saveContract(getNetworkName(block.chainid), "NFTMarket", address(nftMarket));

        vm.stopBroadcast();

        console.log("\n=== Deployment Complete ===");
        console.log("Deployer address: ", vm.addr(deployerPrivateKey));
        // console.log("BaseERC20:", address(token));
        // console.log("SimpleNFT:", address(simpleNFT));
        console.log("MyTokenPermit:", address(token));
        console.log("MyNFTPermit:", address(myNFT));
        console.log("NFTMarket:", address(nftMarket));
    }

    // 保存合约部署信息到 JSON 文件
    function saveContract(string memory network, string memory name, address addr) public {
      string memory chainId = vm.toString(block.chainid);
      string memory json1 = "key";

      // 将合约地址序列化为 JSON 格式
      string memory finalJson =  vm.serializeAddress(json1, "address", addr);

      // 创建按网络分类的输出目录（如 deployments/mainnet/1/）
      string memory dirPath = string.concat("deployments/", network, "/", chainId, "/");

      // 如果目录不存在，则创建目录
      if (!vm.isDir(dirPath)) {
        vm.createDir(dirPath, true);
      }

      // 将合约信息写入到指定文件（如 MyContract.json）
      string memory filePath = string.concat(dirPath, name, ".json");

      // 将合约信息写入到指定文件
      vm.writeJson(finalJson, filePath); 
    }

    function getNetworkName(uint256 chainId) public pure returns (string memory) {
        if (chainId == 1) return "mainnet";
        if (chainId == 11155111) return "sepolia"; 
        if (chainId == 31337) return "localhost";
        return "unknown";
    }
}
