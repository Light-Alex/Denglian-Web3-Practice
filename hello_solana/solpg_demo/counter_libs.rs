/**
项目说明：
使用 Anchor 编写一个简单的计数器程序，包含两个指令：

initialize(ctx)：用 seed 派生出账户，初始化 count = 0
increment(ctx)：将账户中的 count 加 1
*/

// 引入 Anchor 框架的预导入模块，包含常用的类型和宏
use anchor_lang::prelude::*;

// 声明此程序的 Program ID（程序唯一标识符）
// 这个 ID 是在部署时由 Solana 生成的，每个程序都有唯一的 ID
declare_id!("BqVNxB4bggMbrAkiV6v5cyREqS4VFjD2d8i1ZAV8C9v5");

// 定义常量：Anchor 判别器（discriminator）的大小
// 每个 Anchor 账户结构体的前 8 字节用于存储类型标识符
pub const ANCHOR_DISCRIMINATOR_SIZE: usize = 8;

// #[program] 宏标记程序的逻辑部分
// 在这个模块中定义的所有函数都可以被外部调用（类似于合约的公开方法）
#[program]
pub mod counter {
    // 引入上级模块的内容，以便使用当前 crate 中定义的类型和常量
    use super::*;

    /// 初始化计数器：创建 PDA 账户并初始化 count = 0
    ///
    /// # 参数
    /// * `ctx` - 上下文，包含账户信息、程序 ID 等
    ///
    /// # 返回值
    /// * `Result<()>` - 成功返回 Ok(())，失败返回错误
    pub fn initialize(ctx: Context<Increment>) -> Result<()> {
        // 从上下文中获取 counter 账户的可变引用
        let counter = &mut ctx.accounts.counter;

        // 用 seed 派生出账户，初始化 count = 0
        counter.count = 0;

        // 输出初始化日志
        msg!("Counter initialized to 0 for user: {}", ctx.accounts.user.key());

        Ok(())
    }

    /// 增加计数器：将账户中的 count 加 1
    ///
    /// # 参数
    /// * `ctx` - 上下文，包含账户信息、程序 ID 等
    ///
    /// # 返回值
    /// * `Result<()>` - 成功返回 Ok(())，失败返回错误
    pub fn increment(ctx: Context<Increment>) -> Result<()> {
        // 从上下文中获取 counter 账户的可变引用
        let counter = &mut ctx.accounts.counter;

        // 从上下文中获取用户的公钥
        let user_public_key = ctx.accounts.user.key();

        // 将 counter 账户中的 count 加 1
        counter.count += 1;

        // 输出日志，显示更新后的计数器值
        msg!(
            "User {user_public_key}'s count: {}",
            counter.count
        );

        // 返回成功，表示函数执行完成
        Ok(())
    }
}

// What we will put inside the Counter PDA
// #[account] 宏用于定义账户数据结构
// 会自动添加 8 字节的判别器（discriminator）作为结构体的第一个字段
#[account]
// #[derive(InitSpace)] 宏用于自动计算结构体的初始化空间大小
// Counter::INIT_SPACE 会在编译时自动计算
#[derive(InitSpace)]
pub struct Counter {
    // 计数器的值（u64 = 64 位无符号整数 = 8 字节）
    pub count: u64,
}

// PDA 账户， 根据用户公钥生成
// #[derive(Accounts)] 宏用于自动实现账户验证逻辑
// 这个结构体定义了 increment 函数需要的账户及其约束条件
#[derive(Accounts)]
pub struct Increment<'info> {
    // #[account(mut)] - 标记此账户可变（因为需要支付租金，余额会变化）
    #[account(mut)]
    pub user: Signer<'info>,

    // #[account(...)] - 定义 PDA（Program Derived Address，程序派生地址）账户的约束
    #[account(
        init_if_needed,                    // 如果账户不存在则创建，如果已存在则跳过初始化
        payer = user,                      // 指定由 user 账户支付创建账户的费用（租金）
        space = ANCHOR_DISCRIMINATOR_SIZE + Counter::INIT_SPACE,  // 计算所需空间：8 字节判别器 + 结构体空间
        seeds=[b"counter", user.key().as_ref()],  // PDA 的种子：使用 "counter" 字符串和用户公钥
        bump                               // 使用 bump 种子（ cannonical bump）来生成 PDA
    )]
    pub counter: Account<'info, Counter>,

    // System Program 是 Solana 的系统程序，用于创建新账户
    pub system_program: Program<'info, System>,
}