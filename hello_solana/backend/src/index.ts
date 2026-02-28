// ==================== 导入模块 ====================
// 导入 Solana Web3.js 核心模块：连接、密钥对、SOL常量、系统程序、公钥
import {
  Connection,
  Keypair,
  LAMPORTS_PER_SOL,
  SystemProgram,
  PublicKey,
} from "@solana/web3.js";

// 导入 Anchor 框架核心模块：Program、BN（BigNumber）、Provider
import { Program, BN, AnchorProvider } from "@coral-xyz/anchor";

// 导入程序的 IDL（接口定义语言）文件，用于类型安全的交互
import idl from "./idl/favorites.json";

// 导入配置：RPC 端点、支付者密钥对路径
import { RPC_ENDPOINT, PAYER_KEYPAIR_PATH } from "./config";

// 导入 Favorites 程序的 TypeScript 类型定义
import { Favorites } from "./types/favorites";

// 导入 Node.js 文件系统模块，用于读取密钥对文件
import fs from "fs";

// ==================== 主函数 ====================
// 主函数：使用 async/await 处理异步操作
async function main() {
  // ==================== 1. 建立连接 ====================
  // 连接本地节点，使用 "confirmed" 承诺级别（交易确认级别）
  const connection = new Connection(RPC_ENDPOINT, "confirmed");

  // ==================== 2. 创建钱包 ====================
  // 生成钱包
  // 方式 1: 生成新的随机密钥对（每次运行都会创建新账户）
  // const payer = Keypair.generate();

  // 方式 2: 从文件加载已有的密钥对（推荐用于开发和测试）
  const payer = Keypair.fromSecretKey(Buffer.from(JSON.parse(fs.readFileSync(PAYER_KEYPAIR_PATH, "utf8"))));

  // ==================== 3. 创建 Anchor 钱包适配器 ====================
  // 从 Keypair 创建 AnchorWallet - Anchor 需要特定结构的钱包对象，这里手动创建一个适配器
  const createAnchorWallet = (keypair: Keypair) => ({
    publicKey: keypair.publicKey,                    // 钱包公钥
    signTransaction: async (tx: any) => {            // 签名单个交易
      tx.partialSign(keypair);                       // 使用密钥对部分签名交易
      return tx;
    },
    signAllTransactions: async (txs: any[]) => {     // 批量签名多个交易
      txs.forEach(tx => tx.partialSign(keypair));    // 遍历并签名每个交易
      return txs;
    },
    payer: keypair,                                  // 支付者密钥对
  });

  // 创建钱包实例
  const wallet = createAnchorWallet(payer);

  // ==================== 4. 创建 Anchor Provider ====================
  // 创建 Provider - Anchor 与 Solana 网络交互的桥梁，包含连接、钱包和承诺级别
  const provider = new AnchorProvider(connection, wallet, {
    commitment: "confirmed",  // 承诺级别：confirmed 表示交易已被网络确认
  });

  // ==================== 5. 创建程序实例 ====================
  // 创建 Program 实例 - 类型安全（使用 IDL 和 TypeScript 类型）
  const program = new Program<Favorites>(idl as Favorites, provider);

  // ==================== 6. 获取最新区块哈希 ====================
  // 获取最新区块的哈希和有效高度，用于交易的生命周期管理（防重放攻击）
  const { blockhash, lastValidBlockHeight } = await connection.getLatestBlockhash();

  // ==================== 7. 检查余额并空投（如果需要） ====================
  // 获取支付者账户的余额（单位：lamports，1 SOL = 1,000,000,000 lamports）
  const balance = await connection.getBalance(payer.publicKey);
  console.log("账户余额:", balance / LAMPORTS_PER_SOL, "SOL");

  // 如果余额少于 10 SOL，则请求空投（仅适用于开发网络和本地网络）
  if (balance < 10 * LAMPORTS_PER_SOL) {
    // Airdrop 一些 SOL 以便支付手续费
    const airdropSignature = await connection.requestAirdrop(
      payer.publicKey,
      10 *LAMPORTS_PER_SOL,  // 空投 10 SOL
    );
    // 等待空投交易确认
    await connection.confirmTransaction({
      signature: airdropSignature,
      blockhash,
      lastValidBlockHeight,
    });
    console.log("Airdrop 完成");
  }

  // ==================== 8. 计算 PDA（程序派生地址） ====================
  // 计算 PDA - 使用种子（"favorites" + 用户公钥）派生唯一的账户地址
  // PDA 确保每个用户都有独立的 favorites 账户
  const [favoritesPda] = PublicKey.findProgramAddressSync(
    [Buffer.from("favorites"), payer.publicKey.toBuffer()],  // 种子：固定字符串 + 用户公钥
    program.programId                                        // 程序 ID
  );

  // ==================== 9. 构建并发送交易 ====================
  // 构建 setFavorites 指令 - 使用 accountsPartial 避免类型检查问题
  // 调用程序的 setFavorites 方法，传入参数：number=43, color="blue"
  const tx = await program.methods
    .setFavorites(new BN(43), "blue")  // BN (BigNumber) 用于处理大整数
    .accountsPartial({                  // 指定交易所需的账户（部分模式，更灵活）
      user: payer.publicKey,            // 用户账户（签名者和支付者）
      favorites: favoritesPda,          // PDA 账户（存储数据）
      systemProgram: SystemProgram.programId,  // 系统程序（用于创建账户）
    })
    .rpc();  // rpc() 方法：发送交易到网络并等待确认
  
  console.log("Transaction Signature", tx);

  // ==================== 10. 获取交易信息 ====================
  // 获取已解析的交易详情，包含日志消息
  const txInfo = await connection.getParsedTransaction(tx);
  console.log("交易日志:", txInfo?.meta?.logMessages);

  // ==================== 11. 获取单个 PDA 账户信息 ====================
  // 获取某个PDA favorites 账户信息（使用 Anchor 的类型安全解析）
  const favoritesAccount = await program.account.favorites.fetch(favoritesPda);
  console.log("Number:", favoritesAccount.number.toString());  // BN 转字符串
  console.log("Color:", favoritesAccount.color);

  // ==================== 12. 获取原始账户信息 ====================
  // 获取 accountinfo（原始的账户数据，未经过 Anchor 解析）
  const accountInfo = await connection.getAccountInfo(favoritesPda);
  console.log("Account Info:", accountInfo);

  // 可选：批量获取多个账户的信息
  // const accounts = await connection.getMultipleAccountsInfo([favoritesPda, payer.publicKey, program.programId]);
  // console.log("Accounts:", accounts);

  // ==================== 13. 获取程序的所有账户 ====================
  // 获取所有 PDA 账户 (使用未解析版本以获得原始数据)
  const allAccounts = await connection.getProgramAccounts(program.programId);
  console.log("All Accounts:", allAccounts.length);

  // 遍历所有账户并解析数据
  for (const account of allAccounts) {
    console.log("Account:", account.pubkey.toBase58());  // 打印账户公钥（Base58 编码）

    // 🔍 解析 Favorites 账户数据
    try {
      // 检查数据类型，只处理 Buffer 类型的数据（排除已解析的 ParsedAccountData）
      if (Buffer.isBuffer(account.account.data)) {
        // 检查数据长度是否足够（至少有 8 字节的 discriminator）
        if (account.account.data.length >= 8) {
          // "favorites" 账户类型 对应 IDL 中的 Favorites 结构体
          // 使用 Anchor 的 coder 手动解码账户数据
          const decodedData = program.coder.accounts.decode("favorites", account.account.data);
          console.log("📊 解析的账户数据:");
          console.log(`  Number: ${decodedData.number.toString()}`);
          console.log(`  Color: ${decodedData.color}`);
        } else {
          console.log("⚠️  账户数据太短，跳过");
        }
      }
    } catch (error: any) {
      // 只在调试时显示详细错误，生产环境可以静默跳过非 favorites 账户
      if (error.message.includes("Invalid account discriminator")) {
        console.log("⚠️  跳过非 favorites 类型账户");
      } else {
        console.log("❌ 解析账户数据失败:", error.message);
      }
    }
  }

  // ==================== 14. 获取交易历史 ====================
  // 🔍 获取程序相关的交易签名 - 优化参数
  console.log("\n📋 获取交易历史...");
  
  // 本地节点数据会丢失（重启后交易历史清空）
  // 获取用户地址相关的所有交易签名
  const userSignatures = await connection.getSignaturesForAddress(payer.publicKey);
  console.log(`用户账户交易数: ${userSignatures.length}`);

  // 📊 显示用户相关的交易详情
  if (userSignatures.length > 0) {
    console.log("\n🔍 最近的用户交易:");
    for (const sig of userSignatures.slice(0, 2)) { // 只显示前 2 个交易
      console.log(`  签名: ${sig.signature}`);
      console.log(`  状态: ${sig.err ? '失败' : '成功'}`);
      console.log(`  Slot: ${sig.slot}`);
      
      // 获取交易详情（包含日志消息）
      const txDetail = await connection.getParsedTransaction(sig.signature);
      console.log("Transaction Info:", txDetail?.meta?.logMessages);
    }
  }

}

// ==================== 执行主函数 ====================
// 执行主函数并捕获任何错误
main().catch(console.error); 
