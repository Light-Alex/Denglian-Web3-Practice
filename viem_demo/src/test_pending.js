import { ethers } from 'ethers';

const wsUrl = 'wss://sepolia.infura.io/ws/v3/27bd57918fe44bba850e1d9325bf32b2';
const wsProvider = new ethers.WebSocketProvider(wsUrl);

let pendingCount = 0;
let startTime = Date.now();

console.log('Testing Infura WebSocket pending transaction feed...');

wsProvider.on('pending', (txHash) => {
    pendingCount++;
    console.log(`Received pending tx #${pendingCount}: ${txHash}`);

    if (pendingCount >= 5) {
        const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
        console.log(`\n✅ Received ${pendingCount} pending transactions in ${elapsed}s`);
        console.log('Infura WebSocket DOES support pending transactions');
        process.exit(0);
    }
});

// 10秒后超时
setTimeout(() => {
    if (pendingCount === 0) {
        console.log('❌ No pending transactions received in 10 seconds');
        console.log('Infura WebSocket may NOT support pending transactions on free tier');
    } else {
        console.log(`\n⚠️  Only received ${pendingCount} pending transactions in 10 seconds`);
    }
    process.exit(0);
}, 10000);
