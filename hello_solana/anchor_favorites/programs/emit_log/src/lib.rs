use anchor_lang::prelude::*;

declare_id!("D9QjqN8PuzRVf2nxWcAa4TfbitBM3Aw1ehaoo6Lt8j2D");

pub const ANCHOR_DISCRIMINATOR_SIZE: usize = 8;

#[program]
pub mod emit_log {
    use super::*;

    pub fn initialize(ctx: Context<Initialize>) -> Result<()> {
        msg!("Program ID: {} will emit log", ctx.program_id);
        emit!(MyEvent { value: 12 });
        emit!(MySecondEvent { value: 3, message: "hello world".to_string() });
        Ok(())
    }
}

#[derive(Accounts)]
pub struct Initialize {}

#[event]
pub struct MyEvent {
    pub value: u64,
}

#[event]
pub struct MySecondEvent {
    pub value: u64,
    pub message: String,
}