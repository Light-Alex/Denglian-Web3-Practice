// 引入 Anchor 框架的预导入模块，包含常用的类型和宏
use anchor_lang::prelude::*;

// 声明此程序的 Program ID（程序唯一标识符）
// 这个 ID 是在部署时由 Solana 生成的，每个程序都有唯一的 ID
declare_id!("BqVNxB4bggMbrAkiV6v5cyREqS4VFjD2d8i1ZAV8C9v5");

// #[program] 宏标记程序的逻辑部分
// 在这个模块中定义的所有函数都可以被外部调用（类似于合约的公开方法）
#[program]
mod Adder {
    // 引入上级模块的内容，以便使用当前 crate 中定义的类型
    use super::*;

    /// 加法函数：计算两个数的和并打印日志
    ///
    /// # 参数
    /// * `ctx` - 上下文，包含账户信息、程序 ID 等
    /// * `d1` - 第一个加数（u64 类型，64 位无符号整数）
    /// * `d2` - 第二个加数（u64 类型，64 位无符号整数）
    ///
    /// # 返回值
    /// * `Result<()>` - 成功返回 Ok(())，失败返回错误
    pub fn add(ctx: Context<Add>, d1: u64, d2: u64) -> Result<()> {
        // msg! 宏用于输出程序日志，可以在链上查看
        // 计算两数之和并输出日志信息
        msg!("Sum is: {}!", d1 + d2);
        // 返回成功，表示函数执行完成
        Ok(())
    }
}

// #[derive(Accounts)] 宏用于自动实现账户验证逻辑
// 这个结构体定义了函数需要的账户及其约束条件
#[derive(Accounts)]
pub struct Add {}
