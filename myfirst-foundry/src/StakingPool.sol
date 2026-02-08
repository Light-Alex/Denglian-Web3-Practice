// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/StakingInterfaces.sol";
import "./interfaces/IWETH9.sol";
import "./interfaces/IPool.sol";

contract StakingPool is IStaking {

    IToken public kkToken;
    IPool public lendingPool; // Aave V3 借贷池
    IWETH9 public weth;
    address public owner;
    
    uint256 public constant REWARD_PER_BLOCK = 10 * 1e18; // 每个区块奖励 10 KK Token
    uint256 public totalStaked; // 总质押 ETH 数量
    uint256 public lastRewardBlock; // 上次更新奖励的区块号
    uint256 public accRewardPerShare; // 每个质押 ETH 对应的奖励 per share: += (奖励金额 / 质押 ETH 数量)
    
    struct UserInfo {
        uint256 amount; // 质押的 ETH 数量
        uint256 rewardDebt; // 用户债务
        uint256 stakingTime; // 用户开始质押的区块时间
    }
    
    mapping(address => UserInfo) public userInfo;
    
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 reward);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    constructor(address _kkToken, address _weth, address _lendingPool) {
        kkToken = IToken(_kkToken);
        weth = IWETH9(_weth);
        lendingPool = IPool(_lendingPool);
        owner = msg.sender;
        lastRewardBlock = block.number;
    }
    
    // 更新区块奖励: accRewardPerShare, lastRewardBlock
    function updateReward() public {
        if (block.number <= lastRewardBlock || totalStaked == 0) {
            lastRewardBlock = block.number;
            return;
        }
        
        uint256 diff = block.number - lastRewardBlock;
        uint256 reward = diff * REWARD_PER_BLOCK;
        accRewardPerShare += (reward * 1e12) / totalStaked;
        lastRewardBlock = block.number;
    }
    
    /**
     * @dev 质押 ETH 到合约
     */
    function stake() external payable override {
        require(msg.value > 0, "Cannot stake 0");

        // 更新区块奖励
        updateReward();
        
        UserInfo storage user = userInfo[msg.sender];
        
        // 发放待领取的奖励(结算用户之前质押的奖励)
        if (user.amount > 0) {
            uint256 pending = (user.amount * accRewardPerShare) / 1e12 - user.rewardDebt;
            if (pending > 0) {
                kkToken.mint(msg.sender, pending);
            }
        } else {
            user.stakingTime = block.timestamp;
        }
        
        user.amount += msg.value;
        totalStaked += msg.value;
        user.rewardDebt = (user.amount * accRewardPerShare) / 1e12;
        
        // 存入借贷市场
        if (address(lendingPool) != address(0)) {
            weth.deposit{value: msg.value}();
            weth.approve(address(lendingPool), msg.value);
            lendingPool.supply(address(weth), msg.value, address(this), 0);
        }
        
        emit Staked(msg.sender, msg.value);
    }
    
    /**
     * @dev 赎回质押的 ETH
     * @param amount 赎回数量
     */
    function unstake(uint256 amount) external override {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= amount && amount > 0, "Invalid amount");
        
        // 更新区块奖励
        updateReward();
        
        // 结算用户之前质押的奖励
        uint256 pending = (user.amount * accRewardPerShare) / 1e12 - user.rewardDebt;
        
        user.amount -= amount;
        totalStaked -= amount;
        
        if (user.amount == 0) {
            user.stakingTime = 0;
        }
        
        user.rewardDebt = (user.amount * accRewardPerShare) / 1e12;
        
        // 发放奖励
        if (pending > 0) {
            kkToken.mint(msg.sender, pending);
        }
        
        // 从借贷市场提取
        if (address(lendingPool) != address(0)) {
            lendingPool.withdraw(address(weth), amount, address(this));
            weth.withdraw(amount);
        }
        
        payable(msg.sender).transfer(amount);
        emit Unstaked(msg.sender, amount);
    }
    
    /**
     * @dev 领取 KK Token 收益
     */
    function claim() external override {
        // 更新区块奖励
        updateReward();
        
        UserInfo storage user = userInfo[msg.sender];

        // 结算 KK Token 收益
        uint256 pending = (user.amount * accRewardPerShare) / 1e12 - user.rewardDebt;
        
        require(pending > 0, "No rewards");
        
        user.rewardDebt = (user.amount * accRewardPerShare) / 1e12;

        // 发放奖励
        kkToken.mint(msg.sender, pending);
        
        emit Claimed(msg.sender, pending);
    }
    
    /**
     * @dev 获取质押的 ETH 数量
     * @param account 质押账户
     * @return 质押的 ETH 数量
     */
    function balanceOf(address account) external view override returns (uint256) {
        return userInfo[account].amount;
    }
    
    /**
     * @dev 获取待领取的 KK Token 收益
     * @param account 质押账户
     * @return 待领取的 KK Token 收益
     */
    function earned(address account) external view override returns (uint256) {
        UserInfo memory user = userInfo[account];
        if (user.amount == 0) return 0;
        
        uint256 currentAcc = accRewardPerShare;
        if (block.number > lastRewardBlock && totalStaked > 0) {
            uint256 diff = block.number - lastRewardBlock;
            uint256 reward = diff * REWARD_PER_BLOCK;
            currentAcc += (reward * 1e12) / totalStaked;
        }
        
        return (user.amount * currentAcc) / 1e12 - user.rewardDebt;
    }
    
    /**
     * @dev 获取用户开始质押的区块时间
     * @param account 质押账户
     * @return 质押区块时间
     */
    function getStakingTime(address account) external view returns (uint256) {
        return userInfo[account].stakingTime;
    }
    
    /**
     * @dev 更新借贷市场地址
     * @param _lendingPool Aave V3 借贷池地址
     */
    function updateLendingPool(address _lendingPool) external onlyOwner {
        lendingPool = IPool(_lendingPool);
    }
    
    /**
     * @dev 紧急提取当前合约中的ETH
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(owner).transfer(balance);
        }
    }
    
    // 接收ETH
    receive() external payable {}
}