// Contract addresses - Sepolia Testnet only

// V1 Contracts
export const CONTRACTS_V1 = {
  MyToken: '0x5FbDB2315678afecb367f032d93F642f64180aa3',
  TokenBank: '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512',
} as const;

// V2 Contracts
export const CONTRACTS_V2 = {
  MyTokenV2: '0x2023Bb8d3e166fcA393BB1D1229E74f5D47939e0',
  TokenBankV2: '0x2219d42014E190D0C4349A6A189f4d11bc92669B',
} as const;

// Permit (EIP-2612) Contracts
export const CONTRACTS_PERMIT = {
  MyTokenPermit: '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512',
  TokenBankPermit: '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0',
} as const;

// Permit2 Contracts
export const CONTRACTS_PERMIT2 = {
  MyToken: '0xC3310c7E1CA7a494D494C6B55BedADD19C6D4fc8',
  TokenBankPermit2: '0x4b3045a44d327b2Bee0ed1B6F8a2fB817F82B3ba',
  Permit2: '0x000000000022D473030F116dDEE9F6B43aC78BA3', // Official Uniswap Permit2 on Sepolia
} as const;

// Delegate Contract (EIP-7702)
export const CONTRACTS_DELEGATE = {
  Delegate: '0xD842b1A2551dB2F691745984076F3b4bf87485c8',
} as const;

// 默认导出V1（向后兼容）
export const CONTRACTS = CONTRACTS_V1;
