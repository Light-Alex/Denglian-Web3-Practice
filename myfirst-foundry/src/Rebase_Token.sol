// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 🧪 一个整合案例
// 假设市场上有且仅有2个持有者：
// Alice：持有80 AMPL
// Bob：持有20 AMPL
// 总供给：100 AMPL

// 市价：1.50美元（需求旺盛，价格高于锚定）
// 当日“再计价”发生：
// 判断：价格1.5 > 1.05（阈值），系统决定增加总供给50%。
// 全局调整：
// 新总供给 = 100 * 1.5 = 150 AMPL
// Alice新余额 = 80 * 1.5 = 120 AMPL（她仍占150枚中的80%）
// Bob新余额 = 20 * 1.5 = 30 AMPL（他仍占150枚中的20%）
// 预期市场行为：Alice和Bob发现钱包里的AMPL变多了。如果他们都认为当前1.5美元的价格不可持续，可能会卖出部分新增的AMPL获利。卖盘的增加有望使价格回落。

// 相反情况：如果市价为0.8美元，系统会按比例减少所有人的余额（如减少20%）。Alice和Bob的资产“缩水”，可能促使他们减少卖出或开始买入，买盘的增加或卖盘的减少有望推动价格上涨。

/**
 * @title RebaseToken
 * @dev 通缩型 Rebase Token 实现
 * 起始发行量为 1 亿，每年通缩 1%
 * 参考 Ampleforth 的实现原理
 */
contract RebaseToken {
    // 使用 Gons（高精度单位）存储用户余额(Gons的数量)，避免 rebase 时精度损失
    // Gons 是内部的记账单位，外部显示的余额（token 数量） = gons / gonsPerFragment
    mapping(address => uint256) private _gonBalances;

    // 授权映射：owner[holder][spender] = 允许 spender 代表 holder 花费的金额(token数量)
    mapping(address => mapping(address => uint256)) private _allowances;

    // uint256 最大值（2^256 - 1）
    uint256 private constant MAX_UINT256 = ~uint256(0);

    // 初始代币供应量：1 亿个 token（每个 18 位小数）
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 100_000_000 * 10**18;

    // 总 Gons 数量：确保所有 Gons 能被初始供应量整除，避免精度损失
    // 通过取模运算确保 TOTAL_GONS 是 INITIAL_FRAGMENTS_SUPPLY 的整数倍
    // 目的: 找到一个尽可能大的数值，同时这个数值必须能被初始代币总量整除
    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    // ERC20 标准元数据
    string public name = "Rebase Deflation Token"; // 代币名称
    string public symbol = "RDT"; // 代币符号
    uint8 public decimals = 18; // 小数位数

    // 代币总量（会随着 rebase 变化）
    uint256 private _totalSupply;

    // 每个 token 对应的 Gons 数量（用于转换：token = gons / gonsPerFragment）
    // rebase 时会调整这个值，从而改变所有用户持有的 token 数量
    uint256 private _gonsPerFragment;

    // Rebase 相关状态变量
    uint256 public lastRebaseTime; // 上次 rebase 的时间戳
    uint256 public rebaseCount; // rebase 执行次数（纪元数）
    address public owner; // 合约所有者（可以手动触发 rebase）

    // 通缩配置常量
    uint256 private constant DEFLATION_RATE = 99; // 通缩率 99%（即每次减少 1%）
    uint256 private constant RATE_DENOMINATOR = 100; // 分母 100%
    uint256 private constant REBASE_INTERVAL = 365 days; // Rebase 间隔：365 天

    // ERC20 标准事件
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Rebase 事件：记录每次 rebase 的纪元数和新的总供应量
    event Rebase(uint256 indexed epoch, uint256 totalSupply);

    // 仅所有者修饰符：限制某些函数只能由合约 owner 调用
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // 构造函数：部署合约时调用一次
    constructor() {
        owner = msg.sender; // 设置部署者为 owner

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY; // 初始化总供应量为 1 亿

        // 计算 gonsPerFragment：将总 GONS 分配给每个 token
        // 例如：TOTAL_GONS / 100,000,000 = 每个 token 对应多少 gons
        _gonsPerFragment = TOTAL_GONS / _totalSupply;

        lastRebaseTime = block.timestamp; // 记录部署时间为首次 rebase 时间

        // 将所有 GONS 分配给部署者
        _gonBalances[msg.sender] = TOTAL_GONS;
        
        // 触发铸造事件（从零地址转账到部署者）
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    // 查询当前代币总供应量
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // 查询地址的代币余额
    // 关键：将内部 Gons 转换为外部显示的 token 数量
    function balanceOf(address who) public view returns (uint256) {
        return _gonBalances[who] / _gonsPerFragment;
    }

    // 转账函数：从调用者转账到 to 地址
    // value: 要转账的 token 数量
    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0), "Transfer to zero address"); // 不允许转到零地址
        require(to != address(this), "Transfer to contract"); // 不允许转到合约本身

        // 将 token 数量转换为 Gons 数量
        uint256 gonValue = value * _gonsPerFragment;

        // 更新发送者和接收者的 Gons 余额
        _gonBalances[msg.sender] -= gonValue;
        _gonBalances[to] += gonValue;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    // 查询授权额度：owner 授权 spender 可以使用的代币数量(token数量)
    function allowance(address owner_, address spender) public view returns (uint256) {
        return _allowances[owner_][spender];
    }

    // 授权转账：从 from 地址转账到 to 地址（需要提前授权）
    // value: 要转账的 token 数量
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0), "Transfer to zero address");
        require(to != address(this), "Transfer to contract");

        // 扣除授权额度
        _allowances[from][msg.sender] -= value;
        // 转换 token 数量为 Gons 并更新余额
        uint256 gonValue = value * _gonsPerFragment;
        _gonBalances[from] -= gonValue;
        _gonBalances[to] += gonValue;
        emit Transfer(from, to, value);
        return true;
    }

    // 授权函数：授权 spender 可以使用调用者的代币
    // spender: 被授权的地址
    // value: 授权的 token 数量
    function approve(address spender, uint256 value) public returns (bool) {
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    // 增加授权额度：在现有授权基础上增加额度
    // spender: 被授权的地址
    // addedValue: 要增加的授权 token 数量
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _allowances[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    // 减少授权额度：在现有授权基础上减少额度
    // spender: 被授权的地址
    // subtractedValue: 要减少的授权 token 数量
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 oldValue = _allowances[msg.sender][spender];
        // 如果减少的值大于等于当前授权，则将授权设为 0
        if (subtractedValue >= oldValue) {
            _allowances[msg.sender][spender] = 0;
        } else {
            _allowances[msg.sender][spender] = oldValue - subtractedValue;
        }
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    // 定期 Rebase 函数：只有在满足时间间隔（365 天）后才能调用
    // 每年自动通缩 1%
    function rebase() external onlyOwner {
        require(block.timestamp >= lastRebaseTime + REBASE_INTERVAL, "Rebase too early");
        _rebase();
    }

    // 手动 Rebase 函数：允许 owner 随时触发 rebase（不检查时间间隔）
    // 用于紧急情况或测试
    function manualRebase() external onlyOwner {
        _rebase();
    }

    // 内部 Rebase 实现函数
    function _rebase() internal {
        rebaseCount++; // 增加 rebase 计数（纪元数）

        // 计算新的总供应量：当前总量 × 99% = 减少 1%
        // 例如：100,000,000 × 99 / 100 = 99,000,000
        uint256 newTotalSupply = (_totalSupply * DEFLATION_RATE) / RATE_DENOMINATOR;
        _totalSupply = newTotalSupply;

        // 关键：调整 gonsPerFragment，使所有用户的余额按比例减少
        // 公式：新 gonsPerFragment = TOTAL_GONS / 新总供应量
        // 由于用户的 _gonBalances 不变，但 _gonsPerFragment 变大了，
        // 所以 balanceOf() = _gonBalances / _gonsPerFragment 的结果会变小
        _gonsPerFragment = TOTAL_GONS / _totalSupply;

        lastRebaseTime = block.timestamp; // 更新 rebase 时间
        emit Rebase(rebaseCount, _totalSupply); // 触发 rebase 事件
    }

    // 查询当前的 gonsPerFragment 值
    // 用于理解当前 token 和 gons 的转换比例
    function gonsPerFragment() external view returns (uint256) {
        return _gonsPerFragment;
    }

    // 检查是否可以执行定期 rebase
    // 返回 true 表示距离上次 rebase 已经过 365 天
    function canRebase() external view returns (bool) {
        return block.timestamp >= lastRebaseTime + REBASE_INTERVAL;
    }

    // 查询下一次可以进行 rebase 的时间戳
    function nextRebaseTime() external view returns (uint256) {
        return lastRebaseTime + REBASE_INTERVAL;
    }

    // 查询地址的原始 Gons 余额（内部记账单位）
    // 仅用于调试或验证，实际显示的余额需要除以 gonsPerFragment
    function gonBalanceOf(address who) external view returns (uint256) {
        return _gonBalances[who];
    }
}