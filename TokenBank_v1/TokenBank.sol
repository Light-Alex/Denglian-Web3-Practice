// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
}

contract TokenBank {
    IERC20 public token;
    
    // 记录每个用户的代币数量
    mapping(address => uint256) public balances;

    // 定义事件
    event Deposit(address indexed _user, uint256 amount);
    event Withdraw(address indexed _user, uint256 amount);

    constructor(address _token) public {
        require(_token != address(0), "Token Bank: token address cannot not be zero");
        token = IERC20(_token);
    }

    function deposit(uint256 _amount) public {
        require(_amount > 0, "Token Bank: deposit value must be greater than zero");
        require(token.balanceOf(msg.sender) >= _amount, "Token Bank: deposit amount exceeds balance");

        require(token.transferFrom(msg.sender, address(this), _amount), "Token Bank: transfer failed");
        balances[msg.sender] += _amount;
        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) public {
        require(_amount > 0, "Token Bank: withdraw value must be greater than zero");
        require(_amount <= balances[msg.sender], "Token Bank: withdraw value exceeds balance");

        // 先更新余额，再转账，防止重入攻击
        balances[msg.sender] -= _amount;

        require(token.transfer(msg.sender, _amount), "Token Bank: transfer failed");
        
        emit Withdraw(msg.sender, _amount);
    }

    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "Token Bank: owner address cannot be zero");
        return balances[_owner];
    }
}