// 引入 Anchor 框架的预导入模块，包含常用的类型和宏
use anchor_lang::prelude::*;

// 声明此程序的 Program ID（程序唯一标识符）
// 这个 ID 是在部署时由 Solana 生成的，每个程序都有唯一的 ID
declare_id!("ASY74LTn3x8Ms5L8FfRXDwnrvRnwWZuURvSLqtcHwKqd");

// 定义常量：Anchor 判别器（discriminator）的大小
// 每个 Anchor 账户结构体的前 8 字节用于存储类型标识符
pub const ANCHOR_DISCRIMINATOR_SIZE: usize = 8;

// #[program] 宏标记程序的逻辑部分
// 在这个模块中定义的所有函数都可以被外部调用（类似于合约的公开方法）
#[program]
pub mod favorites {
    // 引入上级模块的内容，以便使用当前 crate 中定义的类型和常量
    use super::*;

    /// 设置用户的最爱数字和颜色
    ///
    /// # 参数
    /// * `context` - 上下文，包含账户信息、程序 ID 等
    /// * `number` - 用户的最爱数字（u64 类型，64 位无符号整数）
    /// * `color` - 用户的最爱颜色（String 类型，字符串）
    ///
    /// # 返回值
    /// * `Result<()>` - 成功返回 Ok(())，失败返回错误
    pub fn set_favorites(
        context: Context<SetFavorites>, number: u64,  color: String,
    ) -> Result<()> {
        // 输出程序 ID 的问候日志
        msg!("Greetings from {}", context.program_id);

        // 从上下文中获取用户的公钥
        let user_public_key = context.accounts.user.key();

        // 输出用户的最爱设置信息到日志
        msg!(
            "User {user_public_key}'s favorite number is {number}, favorite color is: {color}",
        );

        // 使用 set_inner 方法更新 favorites 账户的数据
        // set_inner 是 Anchor 提供的便捷方法，用于一次性更新整个结构体
        context.accounts.favorites.set_inner(Favorites {
            number,  // 设置最爰数字
            color,   // 设置最爰颜色
        });

        // 返回成功，表示函数执行完成
        Ok(())
    }
}

// What we will put inside the Favorites PDA
// #[account] 宏用于定义账户数据结构
// 会自动添加 8 字节的判别器（discriminator）作为结构体的第一个字段
#[account]
// #[derive(InitSpace)] 宏用于自动计算结构体的初始化空间大小
// Favorites::INIT_SPACE 会在编译时自动计算
#[derive(InitSpace)]
pub struct Favorites {
    // 用户的最爱数字（u64 = 64 位无符号整数 = 8 字节）
    pub number: u64,

    // 用户的最爱颜色（字符串类型）
    // #[max_len(50)] 约束字符串的最大长度为 50 个字符
    #[max_len(50)]
    pub color: String,
}

// PDA 账户， 根据用户公钥生成
// #[derive(Accounts)] 宏用于自动实现账户验证逻辑
// 这个结构体定义了 set_favorites 函数需要的账户及其约束条件
#[derive(Accounts)]
pub struct SetFavorites<'info> {
    // #[account(mut)] - 标记此账户可变（因为需要支付租金，余额会变化）
    #[account(mut)]
    pub user: Signer<'info>,

    // #[account(...)] - 定义 PDA（Program Derived Address，程序派生地址）账户的约束
    #[account(
        init_if_needed,                    // 如果账户不存在则创建，如果已存在则跳过初始化
        payer = user,                      // 指定由 user 账户支付创建账户的费用（租金）
        space = ANCHOR_DISCRIMINATOR_SIZE + Favorites::INIT_SPACE,  // 计算所需空间：8 字节判别器 + 结构体空间
        seeds=[b"favorites", user.key().as_ref()],  // PDA 的种子：使用 "favorites" 字符串和用户公钥
        bump                               // 使用 bump 种子（ cannonical bump）来生成 PDA
    )]
    pub favorites: Account<'info, Favorites>,

    // System Program 是 Solana 的系统程序，用于创建新账户
    pub system_program: Program<'info, System>,
}

