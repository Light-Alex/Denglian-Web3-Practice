import { createPublicClient, http, keccak256, pad } from "viem";
import { foundry } from "viem/chains";

// EsRNT 合约地址（在 anvil 链上已部署）
const ESRNT_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3" as const;

// LockInfo 结构体布局
// struct LockInfo {
//     address user;      // 20 字节
//     uint64 startTime;  // 8 字节
//     uint256 amount;    // 32 字节
// }
// 总计: 60 字节，占用 2 个插槽（slot 0 和 slot 1）
// 每个 slot 是 32 字节

// 从 hex 数据中提取 address
function getAddress(data: `0x${string}`, offset: number): string {
  const addressBytes = data.slice(2 + offset * 2, 2 + offset * 2 + 40);
  return `0x${addressBytes}`;
}

// 从 hex 数据中提取 uint64
function getUint64(data: `0x${string}`, offset: number): bigint {
  const bytes = data.slice(2 + offset * 2, 2 + offset * 2 + 16);
  return BigInt(`0x${bytes}`);
}

// 从 hex 数据中提取 uint256
function getUint256(data: `0x${string}`, offset: number): bigint {
  const bytes = data.slice(2 + offset * 2, 2 + offset * 2 + 64);
  return BigInt(`0x${bytes}`);
}

const main = async () => {
  // 创建公共客户端连接到 anvil 本地节点
  const publicClient = createPublicClient({
    chain: foundry,
    transport: http(process.env.RPC_URL!),
  });

  console.log("🔍 开始读取 EsRNT 合约的 _locks 数组数据...\n");

  // 首先读取数组长度
  // _locks 数组存储在 slot 0
  const arrayData = await publicClient.getStorageAt({
    address: ESRNT_ADDRESS,
    slot: '0x0',
  });

  // 解析数组长度（数组的 length 存储在 slot 0 的前 32 字节）
  const arrayLength = getUint256(arrayData || "0x", 0);
  console.log(`📊 数组长度: ${arrayLength}\n`);

  // 读取数组元素
  // pad是右对齐，不足 32 字节用 0 在左侧填充
  const arrayHash = BigInt(keccak256(pad("0x0", { size: 32 })));
  console.log("📝 arrayHash (BigInt):", arrayHash.toString(16));

  for (let i = 0; i < Number(arrayLength); i++) {
    // 计算当前元素的起始槽位
    const startSlot = `0x${(arrayHash + BigInt(i) * 2n).toString(16)}` as const;

    // 读取第一个槽位（包含 user 和 startTime）
    const slot0Data = await publicClient.getStorageAt({
      address: ESRNT_ADDRESS,
      slot: startSlot,
    });

    // 读取第二个槽位（包含 amount）
    const slot1Data = await publicClient.getStorageAt({
      address: ESRNT_ADDRESS,
      slot: `0x${(arrayHash + BigInt(i) * 2n + 1n).toString(16)}` as const,
    });

    // 解析数据
    // Slot 0: [user (20 bytes)] [startTime (8 bytes)] [padding (4 bytes)]
    const user = getAddress(slot0Data || "0x", 0);
    const startTime = getUint64(slot0Data || "0x", 20);

    // Slot 1: [amount (32 bytes)]
    const amount = getUint256(slot1Data || "0x", 0);

    // 打印结果
    console.log(
      `locks[${i}]: user: ${user}, startTime: ${startTime}, amount: ${amount}`
    );
  }

  console.log("\n✅ 读取完成！");
};

main().catch((error) => {
  console.error("❌ 发生错误:", error);
  process.exit(1);
});
