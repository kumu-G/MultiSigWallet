# 全面指南：构建与部署以太坊多签钱包（MultiSigWallet）智能合约的最佳实践

## MultiSigWallet介绍

这是一个基于以太坊智能合约的简单多签钱包实现。多签钱包允许多个签名者共同控制钱包资金，以增加安全性和透明度。

## 功能

实现⼀个简单的多签合约钱包，合约包含的功能：

- 创建多签钱包时，确定所有的多签持有⼈和签名门槛
- 多签持有⼈可提交提案
- 其他多签⼈确认提案（使⽤交易的⽅式确认即可）
- 达到多签⻔槛、任何⼈都可以执⾏交易

这是一个基于以太坊智能合约的多签钱包实现。多签钱包是一种允许多个签名者共同控制钱包资金的合约。在这个实现中，合约的所有者可以提交提案，然后其他所有者可以确认提案。当提案被确认的次数达到阈值时，提案将被执行。

## 实操

实现原理：

1. 使用数组和结构体来存储提案信息，包括目标地址、转账金额和调用数据。
2. 使用 mapping 来存储所有者和提案 ID 的映射关系，以及提案 ID 和提案的映射关系。
3. 使用 modifier 来限制函数的访问权限，确保只有所有者可以提交和确认提案。
4. 使用事件来记录提案的创建、确认和执行。

用途：

1. 用于多签持有人共同控制钱包资金。
2. 用于实现去中心化交易所、借贷平台等应用。

注意事项

- 地址管理：确保所有者地址的正确性和唯一性。
- 提案验证：提交提案时，验证金额和数据符合预期。
- 确认检查：确认提案时，防止重复确认。
- 执行确认：执行提案前，确认提案已正确确认并达到门槛。

### 什么是MultiSigWallet

MultiSigWallet 是一种多签钱包，它允许多个账户共同控制一个钱包的资产。在MultiSigWallet中，每个账户都有一个权重，这个权重决定了该账户在交易中的投票权。只有当足够的账户（即权重之和大于等于总权重）投票同意后，交易才能被执行。

### MultiSigWallet 的应用场景

MultiSigWallet 可以用于各种需要多个账户共同决策的场景，例如：

- 共同控制公司资产
- 共同管理基金

- 共同控制数字货币资产
- 共同管理智能合约

### MultiSigWallet 的优点

MultiSigWallet 的优点包括：

- 安全性高：由于需要多个账户共同决策，因此即使某个账户被攻击，也不会影响整个钱包的安全。
- 灵活性高：可以根据需要设置不同的权重，以适应不同的场景。
- 可扩展性高：可以添加或删除账户，以适应团队的变化。

## 实操

```shell
forge init MultiSigWallet
cd MultiSigWallet/
code .
touch .env   
touch StudyNotes.md      
```

## 目录结构

```shell
MultiSigWallet on  master [!+?] via 🅒 base 
➜ tree . -L 6 -I 'lib|out|broadcast|cache'

.
├── README.md
├── StudyNotes.md
├── foundry.toml
├── remappings.txt
├── script
│   └── MultiSigWallet.s.sol
├── src
│   ├── MultiSigWallet.sol
│   └── MyToken.sol
└── test
    └── MultiSigWalletTest.sol

4 directories, 12 files

```

## 代码

### `MultiSigWallet.sol` 文件

```solidity
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

```

## 测试

### 测试代码

MultiSigWalletTest.sol 文件

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";
import {MyToken} from "../src/MyToken.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet public msw;
    MyToken public mytoken;

    Account owner = makeAccount("owner");
    Account bob = makeAccount("bob");
    Account alice = makeAccount("alice");
    Account charlie = makeAccount("charlie");

    address[] public owners = [owner.addr, bob.addr, alice.addr];
    uint256 public threshold = 2;

    event TestReceived(address sender, uint256 amount);

    function setUp() public {
        mytoken = new MyToken(owner.addr);
        msw = new MultiSigWallet(owners, threshold);

        vm.deal(owner.addr, 1 ether);
        vm.deal(bob.addr, 1 ether);
        vm.deal(alice.addr, 1 ether);
        vm.deal(charlie.addr, 1 ether);
        vm.deal(address(msw), 1 ether);
    }

    function testSubmitProposal() public {
        vm.startPrank(owner.addr);
        msw.submitProposal(charlie.addr, 1 ether, "transfer");
        assertEq(msw.getProposalsLength(), 1);
        (address target, uint256 value, bytes memory data, bool executed, uint256 confirmations) = msw.getProposal(0);
        assertEq(target, charlie.addr);
        assertEq(value, 1 ether);
        assertEq(data, "transfer");
        assertEq(executed, false);
        assertEq(confirmations, 0);

        vm.stopPrank();
    }

    function testConfirmProposal() public {
        vm.startPrank(owner.addr);
        msw.submitProposal(address(mytoken), 1 ether, "");
        msw.confirmProposal(0);
        vm.stopPrank();
        vm.prank(bob.addr);
        msw.confirmProposal(0);

        assertEq(msw.getProposalsLength(), 1);
        (address target, uint256 value, bytes memory data, bool executed, uint256 confirmations) = msw.getProposal(0);
        assertEq(target, address(mytoken));
        assertEq(value, 1 ether);
        assertEq(data, "");
        assertEq(executed, true);
        assertEq(confirmations, 2);

        require(confirmations >= threshold, "Confirmations should be greater than or equal to the threshold");
        assertGe(confirmations, msw.threshold(), "Confirmations should be greater than or equal to threshold");
        require(msw.isConfirmed(0, owner.addr), "Proposal not confirmed");
    }

    function testConfirmProposalSuccessful() public {
        vm.startPrank(owner.addr);

        msw.submitProposal(charlie.addr, 1 ether, "");
        msw.confirmProposal(0);
        vm.stopPrank();
        vm.prank(bob.addr);
        msw.confirmProposal(0);

        assertEq(msw.getProposalsLength(), 1);
        (address target, uint256 value, bytes memory data, bool executed, uint256 confirmations) = msw.getProposal(0);
        assertEq(target, charlie.addr);
        assertEq(value, 1 ether);
        assertEq(data, "");
        assertEq(executed, true);
        assertEq(confirmations, 2);

        require(confirmations >= threshold, "Confirmations should be greater than or equal to the threshold");
        assertGe(confirmations, msw.threshold(), "Confirmations should be greater than or equal to threshold");
        require(msw.isConfirmed(0, owner.addr), "Proposal not confirmed");
    }

    function testConfirmProposalBelowThreshold() public {
        vm.startPrank(owner.addr);
        msw.submitProposal(charlie.addr, 1 ether, "");
        msw.confirmProposal(0);
        vm.stopPrank();

        assertEq(msw.getProposalsLength(), 1);
        (address target, uint256 value, bytes memory data, bool executed, uint256 confirmations) = msw.getProposal(0);
        assertEq(target, charlie.addr);
        assertEq(value, 1 ether);
        assertEq(data, "");
        assertEq(executed, false);
        assertEq(confirmations, 1); // Only one confirmation

        require(confirmations < threshold, "Confirmations should be less than the threshold");
    }

    function testRepeatedConfirmation() public {
        vm.startPrank(owner.addr);
        msw.submitProposal(charlie.addr, 1 ether, "");
        msw.confirmProposal(0);
        vm.stopPrank();
        vm.prank(bob.addr);
        msw.confirmProposal(0);

        // Attempt to confirm again
        vm.prank(bob.addr);
        try msw.confirmProposal(0) {
            revert("Bob should not be able to confirm the proposal again");
        } catch {}

        // Confirm proposal status
        (address target, uint256 value, bytes memory data, bool executed, uint256 confirmations) = msw.getProposal(0);
        assertEq(target, charlie.addr);
        assertEq(value, 1 ether);
        assertEq(data, "");
        assertEq(executed, true);
        assertEq(confirmations, 2); // Ensure confirmations remain 2
    }

    function testConfirmProposalByDifferentOwners() public {
        vm.startPrank(owner.addr);
        msw.submitProposal(address(mytoken), 1 ether, "");
        msw.confirmProposal(0);
        vm.stopPrank();

        vm.prank(bob.addr);
        msw.confirmProposal(0);

        vm.prank(alice.addr);
        vm.expectRevert("Proposal already executed");
        msw.confirmProposal(0);

        assertEq(msw.getProposalsLength(), 1);
        (address target, uint256 value, bytes memory data, bool executed, uint256 confirmations) = msw.getProposal(0);
        assertEq(target, address(mytoken));
        assertEq(value, 1 ether);
        assertEq(data, "");
        assertEq(executed, true);
        assertEq(confirmations, 2);
    }

    function testInvalidProposal() public {
        vm.startPrank(owner.addr);
        vm.expectRevert("Proposal with invalid address or value should fail");
        try msw.submitProposal(address(0), 0, "invalid") {
            revert("Proposal with invalid address or value should fail");
        } catch {}
        vm.stopPrank();
    }

    function testCancelProposal() public {
        // 提交一个新的提案
        vm.startPrank(owner.addr);
        msw.submitProposal(charlie.addr, 1 ether, ""); // 提交提案
        uint256 proposalId = msw.getProposalsLength() - 1; // 获取提案ID

        // 确保提案已提交
        assertEq(msw.getProposalsLength(), 1);

        // 取消提案
        msw.cancelProposal(proposalId);

        // 确保提案已取消
        // 使用 delete 操作符： 数组的长度不会改变。删除的元素会被重置为默认值
        assertEq(msw.getProposalsLength(), 1, "Proposal should be cancelled");
        vm.stopPrank();

        // 验证提案是否已从映射中删除
        (address target, uint256 value, bytes memory data, bool executed, uint256 confirmations) =
            msw.getProposal(proposalId);
        assertEq(target, address(0));
        assertEq(value, 0);
        assertEq(data, "");
        assertEq(executed, false);
        assertEq(confirmations, 0);
    }
}

```

### 实操测试

```shell
MultiSigWallet on  master [!+?] via 🅒 base took 4.9s 
➜ forge fmt && forge test --match-path ./test/MultiSigWalletTest.sol --show-progress  -vv  
[⠊] Compiling...
No files changed, compilation skipped
test/MultiSigWalletTest.sol:MultiSigWalletTest
  ↪ Suite result: ok. 8 passed; 0 failed; 0 skipped; finished in 10.88ms (13.55ms CPU time)

Ran 8 tests for test/MultiSigWalletTest.sol:MultiSigWalletTest
[PASS] testCancelProposal() (gas: 79855)
[PASS] testConfirmProposal() (gas: 218775)
[PASS] testConfirmProposalBelowThreshold() (gas: 148443)
[PASS] testConfirmProposalByDifferentOwners() (gas: 219828)
[PASS] testConfirmProposalSuccessful() (gas: 217422)
[PASS] testInvalidProposal() (gas: 70026)
[PASS] testRepeatedConfirmation() (gas: 212759)
[PASS] testSubmitProposal() (gas: 119132)
Suite result: ok. 8 passed; 0 failed; 0 skipped; finished in 10.88ms (13.55ms CPU time)

Ran 1 test suite in 348.70ms (10.88ms CPU time): 8 tests passed, 0 failed, 0 skipped (8 total tests)

```

## 部署

### 部署脚本

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";

contract MultiSigWalletScript is Script {
    MultiSigWallet public msw;

    address[] public owners;
    uint256 public threshold = 1;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAccountAddress = vm.envAddress("ACCOUNT_ADDRESS");
        address deployerAddress = vm.addr(deployerPrivateKey);
        owners = [deployerAddress, deployerAccountAddress];
        vm.startBroadcast(deployerPrivateKey);

        msw = new MultiSigWallet(owners, threshold);
        console.log("MultiSigWallet deployed to:", address(msw));

        vm.stopBroadcast();
    }
}

```

### 实操部署

```shell
MultiSigWallet on  master [!+?] via 🅒 base 
➜ source .env                                                  

MultiSigWallet on  master [!+?] via 🅒 base took 17.6s 
➜ forge script --chain sepolia MultiSigWalletScript --rpc-url $SEPOLIA_RPC_URL --account MetaMask --broadcast --verify -vvvv  

[⠊] Compiling...
No files changed, compilation skipped
Traces:
  [1144342] MultiSigWalletScript::run()
    ├─ [0] VM::envUint("PRIVATE_KEY") [staticcall]
    │   └─ ← [Return] <env var value>
    ├─ [0] VM::envAddress("ACCOUNT_ADDRESS") [staticcall]
    │   └─ ← [Return] <env var value>
    ├─ [0] VM::addr(<pk>) [staticcall]
    │   └─ ← [Return] 0x750Ea21c1e98CcED0d4557196B6f4a5974CCB6f5
    ├─ [0] VM::startBroadcast(<pk>)
    │   └─ ← [Return] 
    ├─ [1028302] → new MultiSigWallet@0xDd2fE19ff6F33d1A57FE6e845Ae49A071224c55B
    │   └─ ← [Return] 4462 bytes of code
    ├─ [0] console::log("MultiSigWallet deployed to:", MultiSigWallet: [0xDd2fE19ff6F33d1A57FE6e845Ae49A071224c55B]) [staticcall]
    │   └─ ← [Stop] 
    ├─ [0] VM::stopBroadcast()
    │   └─ ← [Return] 
    └─ ← [Stop] 


Script ran successfully.

== Logs ==
  MultiSigWallet deployed to: 0xDd2fE19ff6F33d1A57FE6e845Ae49A071224c55B

## Setting up 1 EVM.
==========================
Simulated On-chain Traces:

  [1028302] → new MultiSigWallet@0xDd2fE19ff6F33d1A57FE6e845Ae49A071224c55B
    └─ ← [Return] 4462 bytes of code


==========================

Chain 11155111

Estimated gas price: 39.158879778 gwei

Estimated total gas used for script: 1516104

Estimated amount required: 0.059368934266944912 ETH

==========================
Enter keystore password:

##### sepolia
✅  [Success]Hash: 0x19928b01dbf03e0d40d756f36b95f85dc9f8e8629cf0890c57e9369ce7e5748d
Contract Address: 0xDd2fE19ff6F33d1A57FE6e845Ae49A071224c55B
Block: 6447785
Paid: 0.022294817420990006 ETH (1166582 gas * 19.111230433 gwei)

✅ Sequence #1 on sepolia | Total Paid: 0.022294817420990006 ETH (1166582 gas * avg 19.111230433 gwei)
                                                                                                                                        

==========================

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.
##
Start verification for (1) contracts
Start verifying contract `0xDd2fE19ff6F33d1A57FE6e845Ae49A071224c55B` deployed on sepolia

Submitting verification for [src/MultiSigWallet.sol:MultiSigWallet] 0xDd2fE19ff6F33d1A57FE6e845Ae49A071224c55B.

Submitting verification for [src/MultiSigWallet.sol:MultiSigWallet] 0xDd2fE19ff6F33d1A57FE6e845Ae49A071224c55B.
Submitted contract for verification:
        Response: `OK`
        GUID: `rd4kf3ehcf7lewpv8jb19tdgxtrve5deckrmmfhbjesbasq5hp`
        URL: https://sepolia.etherscan.io/address/0xdd2fe19ff6f33d1a57fe6e845ae49a071224c55b
Contract verification status:
Response: `NOTOK`
Details: `Pending in queue`
Contract verification status:
Response: `OK`
Details: `Pass - Verified`
Contract successfully verified
All (1) contracts were verified!

Transactions saved to: /Users/qiaopengjun/Code/solidity-code/MultiSigWallet/broadcast/MultiSigWallet.s.sol/11155111/run-latest.json

Sensitive values saved to: /Users/qiaopengjun/Code/solidity-code/MultiSigWallet/cache/MultiSigWallet.s.sol/11155111/run-latest.json


MultiSigWallet on  master [!+?
```

## 部署成功，浏览器查看

<https://sepolia.etherscan.io/address/0xdd2fe19ff6f33d1a57fe6e845ae49a071224c55b#code>

![image.png](https://img.learnblockchain.cn/attachments/2024/08/wNFtkTca66b2107bb34dc.png)

## 知识

- **EOA 和合约账户在 EVM 上是一样的，有同样的属性 :balance、nonce、code、 state**
- **如果一个合约可以持有资金且可以调用任意合约方法，那么这个合约就是一个智能合约钱包账户**
- **智能合约钱包：支持多签、multicall、密钥替换、找回 ...**
- **ERC4337：账户抽象(Account Abstraction)，抽象了 EOA 与 智能合约钱包的区别**

## 源码

参考：<https://github.com/qiaopengjun5162/MultiSigWallet>

## 参考

- <https://safe.global/wallet>
- <https://eips.ethereum.org/EIPS/eip-4337>
- <https://book.getfoundry.sh/tutorials/solidity-scripting>
