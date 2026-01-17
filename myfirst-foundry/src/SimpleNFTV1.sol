// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title SimpleNFTV1
 * @notice 简单的NFT合约用于测试市场功能（可升级版本）
 */
contract SimpleNFTV1 is Initializable, ERC721URIStorageUpgradeable, OwnableUpgradeable {
    uint256 private _tokenIdCounter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // 禁用构造函数，使用 initialize 替代
        _disableInitializers();
    }

    /**
     * @notice 初始化合约, 替换原来的构造函数
     * @param name NFT名称
     * @param symbol NFT符号
     */
    function initialize(string memory name, string memory symbol) external initializer {
        __ERC721_init(name, symbol);
        __Ownable_init(msg.sender);
    }

    /**
     * @notice 铸造NFT
     * @param to 接收者地址
     * @param uri Token URI
     */
    function mint(address to, string memory uri) external onlyOwner returns (uint256) {
        require(to != address(0), "Invalid recipient");
        uint256 tokenId = _tokenIdCounter++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        return tokenId;
    }

    /**
     * @notice 获取Token URI（由 ERC721URIStorageUpgradeable 提供）
     */
    // tokenURI 函数已经在 ERC721URIStorageUpgradeable 中实现
}
