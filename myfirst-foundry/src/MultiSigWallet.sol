// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
实现⼀个简单的多签合约钱包，合约包含的功能：

1. 创建多签钱包时，确定所有的多签持有⼈和签名门槛
2. 多签持有⼈可提交提案
3. 其他多签⼈确认提案（使⽤交易的⽅式确认即可）
4. 达到多签⻔槛、任何⼈都可以执⾏交易
*/

contract MultiSigWallet {
    // 提案结构体
    struct Proposal {
        address to;  // 目标合约地址
        uint256 value; // 发送的ETH数量
        bytes data; // 调用目标合约的函数数据
        bool executed; // 是否已执行
        uint256 confirmations; // 确认数量
    }

    // 多签持有⼈数组
    address[] public owners;

    // 签名门槛(2/3)
    uint256 public threshold;

    // 提案数组
    Proposal[] public proposals;

    // 记录地址是否是多签持有⼈
    mapping(address => bool) public isOwner;

    // 记录每个多签持有者对每个提案的确认状态
    mapping(uint256 => mapping(address => bool)) public confirmations;

    // 事件
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, address indexed to, uint256 value, bytes data);
    event ProposalConfirmed(uint256 indexed proposalId, address indexed owner);
    event ProposalExecuted(uint256 indexed proposalId, address indexed executor);

    // 修饰器: 仅多签持有⼈可调用
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not owner");
        _;
    }

    // 修饰器: 提案存在且未执行
    modifier proposalExists(uint256 proposalId) {
        require(proposalId < proposals.length, "Proposal does not exist");
        require(!proposals[proposalId].executed, "Proposal already executed");
        _;
    }


    // 修饰器: 提案未确认
    modifier proposalNotConfirmed(uint256 proposalId) {
        require(!confirmations[proposalId][msg.sender], "Proposal already confirmed");
        _;
    }

    // 构造函数: 初始化多签持有⼈和签名门槛
    constructor(address[] memory _owners, uint256 _threshold) {
        require(_owners.length > 0, "Owners required");
        require(_threshold > 0 && _threshold <= _owners.length, "Invalid threshold");

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Owner already added");

            isOwner[owner] = true;
            owners.push(owner);
        }

        // 初始化签名门槛
        threshold = _threshold;
    }


    /**
     * @notice 提交提案
     * @param _target 目标合约地址
     * @param _value 发送的 ETH 数量
     * @param _data 调用数据
     * @return proposalId 提案ID
     */
    function submitProposal(address _target, uint256 _value, bytes memory _data) public onlyOwner returns (uint256 proposalId) {
        proposalId = proposals.length;
        proposals.push(Proposal(_target, _value, _data, false, 0));

        emit ProposalSubmitted(proposalId, msg.sender, _target, _value, _data);
    }


     /**
     * @notice 确认提案
     * @param proposalId 提案ID
     */
    function confirmProposal(uint256 proposalId) public onlyOwner proposalExists(proposalId) proposalNotConfirmed(proposalId) {
        confirmations[proposalId][msg.sender] = true;
        proposals[proposalId].confirmations++;

        emit ProposalConfirmed(proposalId, msg.sender);
    }


     /**
     * @notice 执行提案
     * @param proposalId 提案ID
     */
    function executeProposal(uint256 proposalId) public proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.confirmations >= threshold, "Not enough confirmations");
        require(!proposal.executed, "Proposal already executed");

        proposal.executed = true;

        (bool success, ) = proposal.to.call{value: proposal.value}(proposal.data);
        require(success, "Execution failed");

        emit ProposalExecuted(proposalId, msg.sender);
    }

    /**
     * @notice 获取提案数量
     * @return 提案数量
     */
    function getProposalCount() public view returns (uint256) {
        return proposals.length;
    }

     /**
     * @notice 获取提案详情
     * @param proposalId 提案ID
     * @return 提案详情
     */
    function getProposal(uint256 proposalId) public view returns (Proposal memory) {
        return proposals[proposalId];
    }

     /**
     * @notice 获取多签持有⼈数量
     * @return 多签持有⼈数量
     */
    function getOwnerCount() public view returns (uint256) {
        return owners.length;
    }

    /**
     * @notice 获取提案执行状态
     * @param proposalId 提案ID
     * @return 是否已执行
     */
    function getProposalExecuted(uint256 proposalId) public view returns (bool) {
        require(proposalId < proposals.length, "Proposal does not exist");
        return proposals[proposalId].executed;
    }

    // 允许合约接收 ETH
    receive() external payable {}
}