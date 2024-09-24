// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MultiSigWallet {
    address[] public owners; // 多签持有人地址列表
    uint256 public threshold; // 签名门槛

    struct Proposal {
        address target; // 目标地址
        uint256 value; // 转账金额
        bytes data; // 调用数据
        bool executed; // 提案是否已执行
        uint256 confirmations; // 确认数
        mapping(address => bool) confirmedBy; // 确认者地址映射
    }

    Proposal[] public proposals;

    mapping(address => bool) public isOwner;

    // 修饰符：仅限所有者
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner"); // 检查发送者是否为所有者
        _;
    }

    // 修饰符：检查提案是否存在
    modifier proposalExists(uint256 proposalId) {
        require(proposalId < proposals.length, "Proposal does not exist"); // 检查提案ID是否有效
        _;
    }

    // 修饰符：检查提案是否未执行
    modifier notExecuted(uint256 proposalId) {
        require(!proposals[proposalId].executed, "Proposal already executed");
        _;
    }

    /**
     * @dev 构造函数：初始化合约，设置所有者和签名门槛。创建多签钱包时，确定所有的多签持有⼈和签名门槛
     * @param _owners 多签持有人
     * @param _threshold 多签门槛
     */
    constructor(address[] memory _owners, uint256 _threshold) {
        require(_owners.length > 0, "At least one owner required");
        require(_threshold > 0 && _threshold <= _owners.length, "Invalid threshold");

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner address");
            require(!isOwner[owner], "Duplicate owner");
            isOwner[owner] = true;
            owners.push(owner);
        }
        threshold = _threshold;
    }

    /**
     * @dev submitProposal：允许多签持有人提交提案。提交提案：所有者可以提交提案，提案包括目标地址、转账金额和调用数据。
     * @param target 目标地址
     * @param value 转账金额
     * @param data 调用数据
     */
    function submitProposal(address target, uint256 value, bytes calldata data) external onlyOwner {
        uint256 proposalId = proposals.length; // 获取提案ID
        Proposal storage proposal = proposals.push(); // 创建新提案
        proposal.target = target; // 设置目标地址
        proposal.value = value; // 设置转账金额
        proposal.data = data; // 设置调用数据
        proposal.executed = false; // 初始化为未执行
        proposal.confirmations = 0; // 初始化确认数为0

        emit ProposalCreated(proposalId, target, value, data); // 触发提案创建事件
    }

    /**
     * @dev confirmProposal：允许多签持有人确认提案。确认提案：所有者可以确认提案，提案确认后，确认数加1。
     * @param proposalId 提案ID
     */
    function confirmProposal(uint256 proposalId)
        external
        onlyOwner
        proposalExists(proposalId)
        notExecuted(proposalId)
    {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.confirmedBy[msg.sender], "Proposal already confirmed by sender");

        proposal.confirmedBy[msg.sender] = true;
        proposal.confirmations++;

        emit ProposalConfirmed(proposalId, msg.sender);

        if (proposal.confirmations >= threshold) {
            executeProposal(proposalId);
        }
    }

    /**
     * @dev executeProposal：执行提案。执行提案：提案确认数达到阈值后，执行提案。
     * @param proposalId 提案ID
     * 在确认数达到门槛时执行提案。该函数被 confirmProposal 调用。
     */
    function executeProposal(uint256 proposalId) internal proposalExists(proposalId) notExecuted(proposalId) {
        Proposal storage proposal = proposals[proposalId]; // 获取提案
        require(proposal.confirmations >= threshold, "Insufficient confirmations"); // 检查确认数是否足够
        proposal.executed = true; // 标记为已执行

        // 调用目标地址的函数
        (bool success,) = proposal.target.call{value: proposal.value}(proposal.data);
        emit ProposalExecutionLog(proposalId, proposal.target, proposal.value, proposal.data, success);

        require(success, "Transaction failed");

        emit ProposalExecuted(proposalId);
    }

    function cancelProposal(uint256 proposalId) external onlyOwner proposalExists(proposalId) notExecuted(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.confirmations == 0, "Cannot cancel a confirmed proposal");

        delete proposals[proposalId];
        emit ProposalCancelled(proposalId);
    }

    function getProposalsLength() public view returns (uint256) {
        return proposals.length;
    }

    function isConfirmed(uint256 proposalId, address owner) external view returns (bool) {
        Proposal storage proposal = proposals[proposalId];
        return proposal.confirmedBy[owner];
    }

    function getProposal(uint256 proposalId) external view returns (address, uint256, bytes memory, bool, uint256) {
        Proposal storage proposal = proposals[proposalId];
        return (proposal.target, proposal.value, proposal.data, proposal.executed, proposal.confirmations);
    }

    // Fallback function to accept ether
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    fallback() external payable {
        emit FallbackEvent(msg.sender, msg.value);
    }

    event ProposalCreated(uint256 proposalId, address target, uint256 value, bytes data);
    event ProposalConfirmed(uint256 proposalId, address confirmer);
    event ProposalExecuted(uint256 proposalId);
    event ProposalCancelled(uint256 proposalId);
    event ProposalExecutionLog(uint256 proposalId, address target, uint256 value, bytes data, bool success);

    event Received(address sender, uint256 amount);
    event FallbackEvent(address sender, uint256 amount);
}
