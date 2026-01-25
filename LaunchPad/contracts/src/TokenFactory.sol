// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MemeToken
 * @dev 实现基本的 ERC20 代币，用于创建 Meme 代币
 */
contract MemeToken is ERC20 {
    address public memeCreator;
    address public factory;  // 添加工厂合约地址变量
    uint256 public totalSupply_;
    string private name_;
    string private symbol_;
    uint8 private decimals_;

    constructor() ERC20("MemeToken", "") {}

    /**
     * @dev 初始化 Meme 代币
     * @param _name 代币名称
     * @param _symbol 代币符号
     * @param _decimals 小数位数
     * @param _totalSupply 总供应量
     * @param _creator 创建者地址
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply,
        address _creator
    ) external {
        require(memeCreator == address(0), "Already initialized");
        require(_totalSupply > 0, "Total supply must be greater than 0");
        
        name_ = _name;
        symbol_ = _symbol;
        decimals_ = _decimals;
        totalSupply_ = _totalSupply;
        memeCreator = _creator;
        factory = msg.sender;  // 设置工厂合约地址为调用初始化函数的地址

        _mint(_creator, _totalSupply);
    }

    /**
     * @dev 获取代币名称
     */
    function name() public view override returns (string memory) {
        return name_;
    }

    /**
     * @dev 获取代币符号
     */
    function symbol() public view override returns (string memory) {
        return symbol_;
    }

     /**
     * @dev 获取小数位数
     */
    function decimals() public view override returns (uint8) {
        return decimals_;
    }

    /**
     * @dev 铸造新的代币
     * @param to 接收者地址
     * @return 是否成功
     */
    function mint(address to, uint256 value) external returns (bool) {
        require(msg.sender == factory, "Only factory can mint");  // 使用存储的工厂地址
        
        _mint(to, value);
        return true;
    }
}

/**
 * @title TokenFactory
 * @dev 使用最小代理模式创建 Meme 代币的工厂合约
 */
contract TokenFactory is Ownable {
    using Clones for address;

    // 基础代币实现
    address public implementation;
    
    // 已部署的代币地址映射
    mapping(address => bool) public deployedTokens;

    // 记录已部署的代币
    // name => symbol => address
    mapping(string => mapping(string => address)) public deployedTokensByNameSymbol;

    event MemeDeployed(address indexed tokenAddress, address indexed creator, string name, string symbol, uint8 decimals, uint256 initialSupply);

    /**
     * @dev 构造函数
     */
    constructor() Ownable(msg.sender) {
        // 部署基础代币实现
        implementation = address(new MemeToken());
    }

    /**
     * @dev 部署新的 Meme 代币(Meme发行者调用该函数)
     * @param name 代币名称
     * @param symbol 代币符号
     * @param decimals 小数位数
     * @param initialSupply 初始供应量
     * @return tokenAddr 新部署的代币地址
     */
    function createToken(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 initialSupply
    ) external returns (address tokenAddr) {
        require(initialSupply > 0, "Initial supply must be greater than 0");
        require(decimals <= 18, "Decimals must be less than or equal to 18");
        require(deployedTokensByNameSymbol[name][symbol] == address(0), "Token with this name and symbol already deployed");

        // 使用 Clones 库创建最小代理
        tokenAddr = implementation.clone();
        
        // 初始化代币
        MemeToken(tokenAddr).initialize(name, symbol, decimals, initialSupply, msg.sender);
        
        // 记录已部署的代币
        deployedTokens[tokenAddr] = true;
        deployedTokensByNameSymbol[name][symbol] = tokenAddr;
        
        emit MemeDeployed(tokenAddr, msg.sender, name, symbol, decimals, initialSupply);
        
        return tokenAddr;
    }
}