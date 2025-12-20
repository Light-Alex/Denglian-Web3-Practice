// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract BaseERC20 {
    string public name; 
    string public symbol; 
    uint8 public decimals; 

    uint256 public totalSupply; 

    mapping (address => uint256) balances; 

    mapping (address => mapping (address => uint256)) allowances; 

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() public {
        // write your code here
        // set name,symbol,decimals,totalSupply
        name = "BaseERC20";
        symbol = "BERC20";
        decimals = 18;
        totalSupply = 100000000 * (10 ** uint256(decimals));

        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        // write your code here
        require(_owner != address(0), "ERC20: query balance of zero address");
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        // write your code here
        require(_to != address(0), "Invalid address");
        require(_value <= balances[msg.sender], "ERC20: transfer amount exceeds balance");

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);  
        return true;   
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // write your code here
        require(_from != address(0), "ERC20: transfer from zero address");
        require(_to != address(0), "ERC20: transfer to zero address");
        require(_value <= balances[_from], "ERC20: transfer amount exceeds balance");
        // 确保被授权者（msg.sender）的转账金额不超过代币持有者（_from）授权的额度
        require(_value <= allowances[_from][msg.sender], "ERC20: transfer amount exceeds allowance");

        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value); 
        return true; 
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        // write your code here
        require(_spender != address(0), "ERC20: approve to zero address");

        allowances[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value); 
        return true; 
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {   
        // write your code here
        require(_owner != address(0), "ERC20: query allowance owner is zero address");
        require(_spender != address(0), "ERC20: query allowance spender is zero address");

        return allowances[_owner][_spender];
    }
}