// 引入 Anchor 框架的预导入模块，包含常用的类型和宏
use anchor_lang::prelude::*;

// 声明此程序的 Program ID（程序唯一标识符）
// 这个 ID 是在部署时由 Solana 生成的，每个程序都有唯一的 ID
declare_id!("5Q1bYLAbg91NYUfRaK8YTiHCQwPmZb5GxcKeQ58gsrFG");

// #[program] 宏标记程序的逻辑部分
// 在这个模块中定义的所有函数都可以被外部调用（类似于合约的公开方法）
#[program]
mod StoreNumber {
    // 引入上级模块的内容，以便使用当前 crate 中定义的类型
    use super::*;

    /// 初始化函数：创建新账户并存储数据
    ///
    /// # 参数
    /// * `ctx` - 上下文，包含账户信息、程序 ID 等
    /// * `data` - 要存储的数据（u64 类型，64 位无符号整数）
    ///
    /// # 返回值
    /// * `Result<()>` - 成功返回 Ok(())，失败返回错误
    pub fn initialize(ctx: Context<Initialize>, data: u64) -> Result<()> {
        // 从上下文中获取新创建的账户，并将传入的数据赋值给其 data 字段
        ctx.accounts.new_account.data = data;
        // msg! 宏用于输出程序日志，可以在链上查看
        // Message will show up in the tx logs
        msg!("Changed data to: {}!", data);
        // 返回成功，表示函数执行完成
        Ok(())
    }
}

// #[derive(Accounts)] 宏用于自动实现账户验证逻辑
// 这个结构体定义了 initialize 函数需要的账户及其约束条件
// <'info> 是生命周期参数，用于确保引用在有效期内
#[derive(Accounts)]
pub struct Initialize<'info> {
    // 我们必须指定空间大小以便初始化账户。
    // 前8个字节是默认的账户判别器（discriminator），
    // 接下来的8个字节来自NewAccount.data的u64类型。
    // (u64 = 64位无符号整数 = 8字节)

    // #[account(init)] - 创建一个新账户
    // payer = signer - 指定由 signer 账户支付创建账户的费用（租金）
    // space = 8 + 8 - 指定账户所需的空间大小（8 字节判别器 + 8 字节数据）
    #[account(init, payer = signer, space = 8 + 8)]
    pub new_account: Account<'info, DataStore>,

    // #[account(mut)] - 标记此账户可变（因为需要支付租金，余额会变化）
    #[account(mut)]
    pub signer: Signer<'info>,

    // System Program 是 Solana 的系统程序，用于创建新账户
    pub system_program: Program<'info, System>,
}

// #[account] 宏用于定义账户数据结构
// 会自动添加 8 字节的判别器（discriminator）作为结构体的第一个字段
// discriminator: 告诉 Anchor, 这是 DataStore 类型
#[account]
pub struct DataStore {
    // 存储的数据字段（u64 = 64 位无符号整数 = 8 字节）
    data: u64
}