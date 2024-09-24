# MultiSigWallet

这是一个基于以太坊智能合约的简单多签钱包实现。多签钱包允许多个签名者共同控制钱包资金，以增加安全性和透明度。

## 功能

实现一个简单的多签钱包， 功能：
• 多签持有人可提交交易
• 其他多签人确认交易（使用交易的方式确认即可）
• 达到多签门槛、任何人都可以执行交易

实现⼀个简单的多签合约钱包，合约包含的功能：

创建多签钱包时，确定所有的多签持有⼈和签名门槛
多签持有⼈可提交提案
其他多签⼈确认提案（使⽤交易的⽅式确认即可）
达到多签⻔槛、任何⼈都可以执⾏交易

这是一个基于以太坊智能合约的多签钱包实现。多签钱包是一种允许多个签名者共同控制钱包资金的合约。在这个实现中，合约的所有者可以提交提案，然后其他所有者可以确认提案。当提案被确认的次数达到阈值时，提案将被执行。

## 实现

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