pragma solidity ^0.8.0;

import './interfaces/IUniswapV2Factory.sol';
import './UniswapV2Pair.sol';

// UniswapV2Factory: Uniswap V2 工厂合约
// 负责创建和管理交易对合约
contract UniswapV2Factory is IUniswapV2Factory {
    address public feeTo;         // 接收交易手续费收入的地址
    address public feeToSetter;   // 有权设置feeTo的地址地址

    mapping(address => mapping(address => address)) public getPair;  // 获取两个代币对应的交易对地址
    address[] public allPairs;  // 所有交易对地址的数组

    // event PairCreated(address indexed token0, address indexed token1, address pair, uint);  // 交易对创建事件

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    // 获取所有交易对的数量
    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    // 创建新的交易对
    // 使用CREATE2操作码部署交易对合约，地址由token0和token1确定
    // tokenA和tokenB顺序不重要，会自动排序为token0 < token1
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');  // 确保两个代币地址不同
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);  // 按地址大小排序
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');  // 确保不是零地址
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient  // 确保交易对不存在
        bytes memory bytecode = type(UniswapV2Pair).creationCode;  // 获取合约创建代码
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));  // 使用两个代币地址作为盐值
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)  // 使用CREATE2创建合约
        }
        IUniswapV2Pair(pair).initialize(token0, token1);  // 初始化交易对
        getPair[token0][token1] = pair;  // 存储正向映射
        getPair[token1][token0] = pair; // populate mapping in the reverse direction  // 存储反向映射
        allPairs.push(pair);  // 添加到所有交易对数组
        emit PairCreated(token0, token1, pair, allPairs.length);  // 触发事件
    }

    // 设置手续费接收地址（仅feeToSetter可调用）
    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');  // 检查权限
        feeTo = _feeTo;
    }

    // 设置feeToSetter地址（仅当前feeToSetter可调用）
    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');  // 检查权限
        feeToSetter = _feeToSetter;
    }

    /*
    * 返回 Pair的字节码
    */
    function pair_code() public pure returns(bytes memory){
        return type(UniswapV2Pair).creationCode;
    }

    /*
    * 返回 Pair的字节码哈希
    */
    function pair_codehash() public pure returns(bytes32){
        return keccak256( type(UniswapV2Pair).creationCode );
    }
}
