pragma solidity ^0.8.0;

import './interfaces/IUniswapV2ERC20.sol';
import './libraries/SafeMath.sol';

// UniswapV2ERC20: Uniswap V2 流动性代币的ERC20实现(LP Token)
// 这个合约实现了ERC20标准，用于代表交易对中的流动性份额
contract UniswapV2ERC20 is IUniswapV2ERC20 {
    using SafeMath for uint;

    string public constant name = 'Uniswap V2';  // 代币名称
    string public constant symbol = 'UNI-V2';   // 代币符号
    uint8 public constant decimals = 18;        // 代币精度
    uint  public totalSupply;                   // 总供应量
    mapping(address => uint) public balanceOf;  // 账户余额映射
    mapping(address => mapping(address => uint)) public allowance;  // 授权额度映射

    bytes32 public DOMAIN_SEPARATOR;  // EIP-712域分隔符，用于签名验证
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;  // Permit函数的类型哈希
    mapping(address => uint) public nonces;  // 每个账户的nonce计数器，用于防止签名重放攻击

    // event Approval(address indexed owner, address indexed spender, uint value);  // 授权事件
    // event Transfer(address indexed from, address indexed to, uint value);        // 转账事件

    constructor() {
        // 构造EIP-712域分隔符，用于离线签名授权
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                block.chainid,
                address(this)
            )
        );
    }

    // 内部函数：铸造代币
    // 增加总供应量并将代币分配给指定地址
    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    // 内部函数：销毁代币
    // 从指定地址减少代币并减少总供应量
    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    // 私有函数：处理授权逻辑
    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    // 私有函数：处理转账逻辑
    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    // 外部函数：授权spender使用自己的代币
    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    // 外部函数：转账代币
    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    // 外部函数：从授权账户转账代币
    // 如果授权额度是无限(uint(-1))，则不减少授权额度
    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    // 外部函数：实现EIP-712 permit功能，允许离线签名授权
    // owner: 代币所有者
    // spender: 被授权人
    // value: 授权数量
    // deadline: 签名截止时间
    // v, r, s: 签名的三个组成部分
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');  // 检查签名是否过期
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);  // 从签名中恢复地址
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'UniswapV2: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}
