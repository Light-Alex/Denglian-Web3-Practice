pragma solidity ^0.8.20;

interface IBank {
    function deposit() external payable;
    function getTopNUsers() external view returns (address[3] memory, uint[3] memory);
    function withdraw(uint256 amount) external;
    function withdrawAll() external;
}

contract Bank is IBank {
    address public admin;
    mapping (address => uint) deposits;
    uint private constant TOPN = 3;

    // 存放余额前三名的用户地址
    address[TOPN] public users;

    constructor(){
        admin = msg.sender;
    }

    function _handleDeposit() internal {
        deposits[msg.sender] += msg.value;
        updateUsers(msg.sender);
    }

    // 接收以太币时更新用户数组
    receive() external payable virtual {
        _handleDeposit();
    }

    // 存款函数
    function deposit() external payable virtual {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        _handleDeposit();
    }

    // 更新users数组，保持余额前三名的用户地址
    function updateUsers(address userAddress) private {
        for (uint i = 0; i < users.length; i++) {
            if (users[i] == userAddress) {
                updateTopN();
                return;
            }
        }

        // 如果用户不在前3名，且余额大于第3名用户，替换第3名用户
        if (deposits[userAddress] > deposits[users[2]]) {
            users[2] = userAddress;
            updateTopN();
        }
    }

    function updateTopN() private {
        for (uint i = 0; i < users.length; i++) {
            for (uint j = i + 1; j < users.length; j++) {
                if (deposits[users[i]] < deposits[users[j]]) {
                    address temp = users[i];
                    users[i] = users[j];
                    users[j] = temp;
                }
            }
        }
    }

    // 获取前三名用户的地址及余额
    function getTopNUsers() external view returns (address[TOPN] memory, uint[TOPN] memory) {
        address[TOPN] memory topNUsers;
        uint[TOPN] memory topNDeposits;
        for (uint i = 0; i < TOPN; i++) {
            topNUsers[i] = users[i];
            topNDeposits[i] = deposits[users[i]];
        }
        return (topNUsers, topNDeposits);
    }

    function withdraw(uint256 amount) external {
        require(msg.sender == admin, "Only admin can withdraw");
        require(amount <= address(this).balance, "Insufficient balance");
        (bool status, ) = payable(admin).call{value: amount}("");
        require(status, "Withdrawal failed");
    }

    function withdrawAll() external {
        require(msg.sender == admin, "Only admin can withdraw");
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        (bool status, ) = payable(admin).call{value: balance}("");
        require(status, "Withdrawal failed");
    }
}

contract BigBank is Bank {
    address public immutable owner;

    constructor() Bank() {
        owner = msg.sender;
    }

    modifier depositAmountLimit(uint256 amount) {
        require(amount > 0.001 ether, "Deposit amount must be greater than 0.001 ether");
        _;
    }

    function deposit() external payable override depositAmountLimit(msg.value) {
        _handleDeposit();
    }

    receive() external payable override depositAmountLimit(msg.value) {
        _handleDeposit();
    }

    function changeAdmin(address newAdmin) external {
        require(msg.sender == owner, "Only owner can change admin");
        admin = newAdmin;
    }
}

contract Admin {
    address public immutable owner;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    function adminWithdraw(IBank bank) external {
        require(msg.sender == owner, "Only owner can withdraw");
        bank.withdrawAll();
    }

    function withdrawToOwner() external {
        require(msg.sender == owner, "Only owner can withdraw");

        uint balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        (bool status, ) = payable(owner).call{value: balance}("");
        require(status, "Withdrawal failed");
    }
}