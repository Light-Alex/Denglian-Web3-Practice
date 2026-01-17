// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/console.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";

/**
 * @title SimpleNFTV2
 * @notice 简单的NFT合约用于测试市场功能（可升级版本）
 */
contract SimpleNFTV2 is Initializable, ERC721URIStorageUpgradeable, OwnableUpgradeable {
    uint256 private _tokenIdCounter;

    // 新增变量（在 EIP712 之后）
    mapping(address => uint256) private _nonces;
    bytes32 private constant _PERMIT_TYPEHASH = keccak256("Permit(address spender,uint256 tokenId,uint256 price,uint256 nonce,uint256 deadline)");
    bytes32 private _DOMAIN_SEPARATOR;  // 改为普通状态变量，在 initialize 中初始化

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
     * @notice 重新初始化 EIP712 域分隔符（升级时调用）
     * @custom:oz-upgrades-unsafe-allow reinitialization
     */
    function reinitialize() external reinitializer(2) {
        // 只初始化 _DOMAIN_SEPARATOR，使用已存在的 symbol
        _DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(this.symbol())),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
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


    /** 
     * @notice 允许spender地址使用tokenId的NFT
     * @param spender 授权地址
     * @param tokenId NFT tokenId
     * @param price 授权价格
     * @param deadline 授权过期时间
     * @param v 签名v值
     * @param r 签名r值
     * @param s 签名s值
    */
    function permit(address spender, uint256 tokenId, uint256 price, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(block.timestamp <= deadline, "SimpleNFTV2: expired deadline");
        address owner = ownerOf(tokenId);

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, spender, tokenId, price, _nonces[owner]++, deadline));

        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", _DOMAIN_SEPARATOR, structHash));

        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0) && signer == owner, "SimpleNFTV2: invalid signer");

        _setApprovalForAll(owner, spender, true);
    }

    /**
     * @notice 获取nonce值
     * @param owner token owner地址
     */
    function nonces(address owner) external view returns (uint256) {
        return _nonces[owner];
    }

    /**
     * @notice 获取域名分隔符
     */
    // 获取域分隔符
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _DOMAIN_SEPARATOR;
    }
}
