import { Address, BigInt, Bytes, ethereum } from "@graphprotocol/graph-ts"
import {
  Approval as ApprovalEvent,
  Transfer as TransferEvent
} from "../generated/MyToken/MyToken"
import { Approval, Transfer, User, BalanceSnapshot, TransferWithUser} from "../generated/schema"

const ADDRESS_ZERO = "0x0000000000000000000000000000000000000000"

/**
 * @dev 索引到Approval事件，便触发handleApproval逻辑：对事件字段进行解析，并最终将解析后的实体保存到Graph Node数据库中，以便后续使用GraphQL查询
 * @param event 授权事件
 */
export function handleApproval(event: ApprovalEvent): void {
  // 创建一个 Approval 实体
  // id赋值为tx hash + logIndex
  let entity = new Approval(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )

  // 实体属性赋值
  entity.owner = event.params.owner
  entity.spender = event.params.spender
  entity.value = event.params.value

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  // 保存到 Graph Node 的数据库
  entity.save()
}

/**
 * @dev 解析转账事件，并将解析结果保存Graph Node数据库中，以便后续使用GraphQL查询
 * @param event 转账事件
 */
// 关联查询: 
// {
//   users (first: 5) {    # 查询 users 实体，限制返回前5条记录
//     id                  # 用户地址（主键）
//     balance             # 用户当前余额
//     transfersFrom {     # 该用户作为转出方的所有转账记录
//       id                # 转账记录的唯一ID
//       value             # 转账金额
//     }
//     transfersTo {       # 该用户作为转入方的所有转账记录
//       id                # 转账记录的唯一ID
//       value             # 转账金额
//     }
//   }
// }
export function handleTransfer(event: TransferEvent): void {
  let entity = new Transfer(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.from = event.params.from
  entity.to = event.params.to
  entity.value = event.params.value

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()

  // 更新用户余额
  updateUserBalance(event.params.from, event.params.to, event.params.value)

  // 创建余额快照
  createBalanceSnapshot(event.params.from, event.block)
  createBalanceSnapshot(event.params.to, event.block)

  // 创建TransferWithUser转账实体
  let transferEntity = new TransferWithUser(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )

  let fromUser = User.load(event.params.from.toHex())
  if (!fromUser) {
    return
  }

  let toUser = User.load(event.params.to.toHex())
  if (!toUser) {
    return
  }
  
  transferEntity.from = fromUser.id
  transferEntity.to = toUser.id
  transferEntity.value = event.params.value
  transferEntity.blockNumber = event.block.number
  transferEntity.blockTimestamp = event.block.timestamp
  transferEntity.transactionHash = event.transaction.hash
  transferEntity.save()
}

/**
 * @dev 没有一次转账便调用该函数更新from地址和to地址的余额
 * @param from 转账发起方地址
 * @param to 转账接收方地址
 * @param amount 转账金额
 */
function updateUserBalance(from: Address, to: Address, amount: BigInt): void {
  // 更新from地址余额
  if (from.toHex() != ADDRESS_ZERO) {
    // 从数据库加载from地址用户实体(根据id 用户地址加载)
    let userFrom = User.load(from.toHex())
    if (!userFrom) {
        userFrom = new User(from.toHex())
        userFrom.balance = BigInt.fromI32(0)
    }

    userFrom.balance = userFrom.balance.minus(amount)
    userFrom.save()
  }

  // 更新to地址余额
  if (to.toHex() != ADDRESS_ZERO) {
    let userTo = User.load(to.toHex())

    if (!userTo) {
      userTo = new User(to.toHex())
      userTo.balance = BigInt.fromI32(0)
    }

    userTo.balance = userTo.balance.plus(amount)
    userTo.save()
  }
}

/**
 * @dev 创建用户余额快照
 * @param userAddress 用户地址
 * @param block 区块
 */
function createBalanceSnapshot(userAddress: Address, block: ethereum.Block): void {
  if (userAddress.toHex() == ADDRESS_ZERO) {
    return
  }
  let user = User.load(userAddress.toHex())
  if (!user) {
    return
  }
  let snapshotId = userAddress.toHex() + "-" + block.number.toString()
  let snapshot = BalanceSnapshot.load(snapshotId)
  if (snapshot) {
    return
  }

  snapshot = new BalanceSnapshot(snapshotId)
  snapshot.user = Bytes.fromHexString(userAddress.toHex())
  snapshot.balance = user.balance
  snapshot.blockNumber = block.number
  snapshot.blockTimestamp = block.timestamp
  snapshot.save()
}

// 另一种获取用户余额的思路：
// 可以通过绑定合约实例，直接调用合约的 balanceOf 方法获取指定区块的余额。例如：
// import { MyToken } from "../generated/MyToken/MyToken"

// function getUserBalanceByContract(user: Address): BigInt {
//   // 绑定合约实例，传入合约地址和区块上下文
//   let contract = MyToken.bind(Address.fromString("0x46F88fb8Bf00bA1Bb5516E70b3Ca5De5acb58D1c"))
//   // 通过 try_balanceOf 查询余额（推荐使用 try_ 方法避免revert）
//   // 获取处理事件的区块高度的余额
//   let result = contract.try_balanceOf(user)
//   if (!result.reverted) {
//     return result.value
//   }
//   return BigInt.fromI32(0)
// }