import { ethers } from 'ethers';
import { FlashbotsBundleProvider } from '@flashbots/ethers-provider-bundle';
import 'dotenv/config';

// OpenspaceNFT ABI (简化版，仅包含需要的函数)
const OPENSPACE_NFT_ABI = [
    "function enablePresale() external",
    "function presale(uint256 amount) external payable",
    "function isPresaleActive() external view returns (bool)",
    "function owner() external view returns (address)"
];

class FlashbotBundleExecutor {
    constructor(mode = 'direct') {
        // 验证环境变量
        this.validateEnvVars();

        // 保存执行模式
        this.mode = mode;
        console.log("执行模式:", mode);

        // 初始化 HTTP provider（用于交易执行）
        this.provider = new ethers.JsonRpcProvider(process.env.SEPOLIA_RPC_URL);
        this.signer = new ethers.Wallet(process.env.SEPOLIA_PRIVATE_KEY2, this.provider);

        // 在监控模式下，添加 WebSocket provider（用于内存池监听）
        if (mode === 'monitor') {
            const wsRpcUrl = this.convertToWebSocket(process.env.SEPOLIA_RPC_URL);
            // const wsRpcUrl = process.env.SEPOLIA_RPC_WSS;
            this.wsProvider = new ethers.WebSocketProvider(wsRpcUrl);
            console.log("WebSocket Provider 已初始化");

            // 添加错误处理
            this.wsProvider.on('error', (error) => {
                console.error("WebSocket Provider 错误:", error.message);
            });
        }

        this.nftContract = new ethers.Contract(
            process.env.OPENSPACE_NFT_ADDRESS,
            OPENSPACE_NFT_ABI,
            this.signer
        );

        // 监控状态管理
        this.monitoringState = {
            isMonitoring: false,
            processedTxHashes: new Set(),
            detectedTxCount: 0,
            lastDetectionTime: null
        };

        console.log("✅ 初始化完成");
        console.log("钱包地址:", this.signer.address);
        console.log("NFT合约地址:", process.env.OPENSPACE_NFT_ADDRESS);
    }

    /**
     * 将 HTTP URL 转换为 WebSocket URL
     * @param {string} httpUrl - HTTP RPC URL
     * @returns {string} WebSocket RPC URL
     */
    convertToWebSocket(httpUrl) {
        return httpUrl
            .replace(/^https?:\/\//, 'wss://')
            .replace(/\/v3\//, '/ws/v3/')  // Infura WebSocket URL uses /ws/v3/
            .replace(/\/$/, '');
    }
    
    validateEnvVars() {
        const requiredVars = ['SEPOLIA_RPC_URL', 'SEPOLIA_PRIVATE_KEY2', 'OPENSPACE_NFT_ADDRESS'];
        for (const varName of requiredVars) {
            if (!process.env[varName]) {
                throw new Error(`缺少环境变量: ${varName}`);
            }
        }
    }
    
    async initFlashbots() {
        try {
            // 初始化Flashbots provider
            this.flashbotsProvider = await FlashbotsBundleProvider.create(
                this.provider,
                this.signer,
                process.env.FLASHBOT_RELAY_URL || 'https://relay-sepolia.flashbots.net'
            );
            console.log("✅ Flashbots provider 初始化成功");
        } catch (error) {
            console.error("❌ Flashbots provider 初始化失败:", error);
            throw error;
        }
    }
    
    async checkContractStatus() {
        try {
            const isActive = await this.nftContract.isPresaleActive();
            const owner = await this.nftContract.owner();
            console.log("📊 合约状态:");
            console.log("- 预售是否激活:", isActive);
            console.log("- 合约owner:", owner);
            console.log("- 当前钱包是否为owner:", owner.toLowerCase() === this.signer.address.toLowerCase());
            return { isActive, owner, isOwner: owner.toLowerCase() === this.signer.address.toLowerCase() };
        } catch (error) {
            console.error("❌ 检查合约状态失败:", error);
            throw error;
        }
    }

    /**
     * 检查交易是否是目标合约的 enablePresale 调用
     * @param {ethers.Transaction} tx - 交易对象
     * @returns {boolean}
     */
    isEnablePresaleTransaction(tx) {
        if (!tx || !tx.data || !tx.to) {
            return false;
        }

        // 检查目标合约地址
        const targetAddress = tx.to.toLowerCase();
        const nftContractAddress = process.env.OPENSPACE_NFT_ADDRESS.toLowerCase();
        if (targetAddress !== nftContractAddress) {
            return false;
        }

        // 检查函数选择器
        // enablePresale() 的函数选择器是 0xa8eac492
        const ENABLE_PRESALE_SELECTOR = '0xa8eac492';
        if (tx.data.startsWith(ENABLE_PRESALE_SELECTOR)) {
            return true;
        }

        return false;
    }

    async createBundleTransactions(includeEnablePresale = true) {
        try {
            console.log("🔨 创建捆绑交易...");

            const currentBlock = await this.provider.getBlockNumber();
            const baseFee = (await this.provider.getFeeData()).gasPrice;
            const nonce = await this.provider.getTransactionCount(this.signer.address);

            console.log("当前区块:", currentBlock);
            console.log("当前nonce:", nonce);

            const transactions = [];

            // 条件性创建 enablePresale 交易
            if (includeEnablePresale) {
                const enablePresaleTx = await this.nftContract.enablePresale.populateTransaction();

                const enablePresaleTransaction = {
                    ...enablePresaleTx,
                    nonce: nonce,
                    gasLimit: 100000n,
                    gasPrice: (baseFee * 110n) / 100n, // 增加10%的gas价格以确保优先级
                    chainId: 11155111 // Sepolia chainId
                };
                transactions.push(enablePresaleTransaction);
                console.log("📝 EnablePresale交易已创建");
            }

            // 总是创建 presale 交易
            const presaleAmount = 1;
            const presaleValue = ethers.parseEther("0.01") * BigInt(presaleAmount);
            const presaleTx = await this.nftContract.presale.populateTransaction(presaleAmount, {
                value: presaleValue
            });

            // nonce 根据是否包含 enablePresale 调整
            const presaleNonce = includeEnablePresale ? nonce + 1 : nonce;

            const presaleTransaction = {
                ...presaleTx,
                nonce: presaleNonce,
                gasLimit: 150000n,
                gasPrice: (baseFee * 150n) / 100n,
                chainId: 11155111,
                value: presaleValue
            };

            transactions.push(presaleTransaction);

            console.log("📝 交易详情:");
            transactions.forEach((tx, index) => {
                const txType = includeEnablePresale
                    ? (index === 0 ? "EnablePresale" : "Presale")
                    : "Presale (监控模式)";
                console.log(`${index + 1}. ${txType}交易:`);
                console.log(`   - Nonce: ${tx.nonce}`);
                console.log(`   - Gas Limit: ${tx.gasLimit.toString()}`);
                console.log(`   - Gas Price: ${ethers.formatUnits(tx.gasPrice, 'gwei')} Gwei`);
                if (tx.value) {
                    console.log(`   - Value: ${ethers.formatEther(tx.value)} ETH`);
                }
            });

            return transactions;
        } catch (error) {
            console.error("❌ 创建交易失败:", error);
            throw error;
        }
    }

    /**
     * 启动内存池监控，监听 pending 交易
     */
    async startMempoolMonitoring() {
        console.log("👁️  开始监控 Sepolia 内存池...");
        console.log("目标合约:", process.env.OPENSPACE_NFT_ADDRESS);
        console.log("目标函数: enablePresale() [0xa8eac492]");
        // console.log("WebSocket URL:", this.convertToWebSocket(process.env.SEPOLIA_RPC_URL));
        console.log("WebSocket URL:", process.env.SEPOLIA_RPC_WSS);

        this.monitoringState.isMonitoring = true;
        this.monitoringState.totalPendingCount = 0;
        this.monitoringState.targetContractTxCount = 0;
        this.monitoringState.startTime = Date.now();

        // 定期打印监控状态
        this.statusInterval = setInterval(() => {
            const elapsed = ((Date.now() - this.monitoringState.startTime) / 1000).toFixed(1);
            console.log(`📊 监控状态: 运行 ${elapsed}秒 | 接收pending交易: ${this.monitoringState.totalPendingCount} | 目标合约交易: ${this.monitoringState.targetContractTxCount}`);
        }, 30000); // 每30秒打印一次

        // 同时启动两种监控方式
        // 方法1: WebSocket 监听 pending 交易
        try {
            this.wsProvider.on('pending', async (txHash) => {
                if (!this.monitoringState.isMonitoring) {
                    return;
                }

                // 统计所有接收到的pending交易
                this.monitoringState.totalPendingCount++;

                // 每100个pending交易打印一次
                if (this.monitoringState.totalPendingCount % 100 === 0) {
                    console.log(`📡 已接收 ${this.monitoringState.totalPendingCount} pending 交易...`);
                }

                // 性能优化：跳过已处理的交易
                if (this.monitoringState.processedTxHashes.has(txHash)) {
                    return;
                }

                // 标记为已处理（防止重复）
                this.monitoringState.processedTxHashes.add(txHash);

                // 定期清理旧哈希（防止内存泄漏）
                if (this.monitoringState.processedTxHashes.size > 10000) {
                    const oldest = Array.from(this.monitoringState.processedTxHashes)[0];
                    this.monitoringState.processedTxHashes.delete(oldest);
                }

                await this.handlePendingTransaction(txHash);
            });
            console.log("✅ WebSocket 监听器已注册");

            // 监听 WebSocket 连接状态
            this.wsProvider.on('error', (error) => {
                console.error("❌ WebSocket 错误:", error.message);
            });
        } catch (error) {
            console.error("❌ WebSocket 监听器失败:", error.message);
            console.log("🔄 仅使用轮询监控模式...");
        }

        // 方法2: 立即启动轮询监控（与 WebSocket 同时运行）
        await this.startPollingMonitor();

        console.log("ℹ️  提示: 监控程序正在等待 enablePresale() 交易...");
        console.log("ℹ️  WebSocket 和轮询模式同时运行，确保不会错过交易");
    }

    /**
     * 启动轮询监控（WebSocket 失败时的后备方案）
     */
    async startPollingMonitor() {
        // 如果已经在轮询，不重复启动
        if (this.pollingInterval) {
            return;
        }

        console.log("🔄 启动轮询监控模式（检查新区块）...");

        // 注意：不清除 WebSocket 监听器，让两者同时运行

        let lastCheckedBlock = await this.provider.getBlockNumber();
        console.log("起始区块:", lastCheckedBlock);

        this.pollingInterval = setInterval(async () => {
            if (!this.monitoringState.isMonitoring) {
                return;
            }

            try {
                const currentBlock = await this.provider.getBlockNumber();

                // 检查新区块
                if (currentBlock > lastCheckedBlock) {
                    for (let blockNum = lastCheckedBlock + 1; blockNum <= currentBlock; blockNum++) {
                        const block = await this.provider.getBlock(blockNum, true);

                        if (block && block.transactions) {
                            for (const tx of block.transactions) {
                                // 处理交易
                                if (typeof tx === 'object' && tx.to) {
                                    if (tx.to.toLowerCase() === process.env.OPENSPACE_NFT_ADDRESS.toLowerCase()) {
                                        this.monitoringState.targetContractTxCount++;

                                        console.log(`\n📝 在区块 ${blockNum} 检测到目标合约交易`);
                                        console.log("   交易哈希:", tx.hash);
                                        console.log("   函数选择器:", tx.data ? tx.data.slice(0, 10) : "0x");

                                        if (this.isEnablePresaleTransaction(tx)) {
                                            this.monitoringState.detectedTxCount++;
                                            this.monitoringState.lastDetectionTime = Date.now();

                                            console.log("\n🎯 发现 enablePresale 交易!");
                                            console.log("交易哈希:", tx.hash);
                                            console.log("区块:", blockNum);
                                            console.log("发送者:", tx.from);
                                            console.log("Gas Price:", ethers.formatUnits(tx.gasPrice || 0n, 'gwei'), "Gwei");

                                            await this.stopMempoolMonitoring();

                                            // 注意：此时交易已经打包，我们只能在下一个区块执行 presale
                                            await this.executePresaleOnly();
                                            return;
                                        }
                                    }
                                }
                            }
                        }
                    }
                    lastCheckedBlock = currentBlock;
                }
            } catch (error) {
                console.error("❌ 轮询监控错误:", error.message);
            }
        }, 3000); // 每3秒检查一次
    }

    /**
     * 轮询模式检测到 enablePresale 后执行 presale（只包含 presale 交易）
     */
    async executePresaleOnly() {
        try {
            console.log("\n🚀 执行 Presale 交易 (轮询模式)...");

            const transactions = await this.createPresaleOnlyBundle(null);

            // 签名交易
            const signedTransactions = [];
            for (const tx of transactions) {
                const signedTx = await this.signer.signTransaction(tx);
                signedTransactions.push(signedTx);
            }

            // 创建 bundle
            const bundle = signedTransactions.map(signedTransaction => ({
                signedTransaction
            }));

            // 发送到 Flashbots
            const currentBlock = await this.provider.getBlockNumber();
            const targetBlock = currentBlock + 1;

            console.log("🎯 目标区块:", targetBlock);
            console.log("📤 提交 Bundle 到 Flashbots...");

            const bundleSubmission = this.flashbotsProvider.sendBundle(bundle, targetBlock);
            const bundleResolution = await bundleSubmission;

            if ('error' in bundleResolution) {
                console.error("❌ Bundle 提交失败:", bundleResolution.error);
                throw new Error(bundleResolution.error.message);
            }

            console.log("✅ Bundle 提交成功!");
            console.log("Bundle Hash:", bundleResolution.bundleHash);

            const bundleInfo = {
                bundleHash: bundleResolution.bundleHash,
                targetBlock: targetBlock,
                transactions: signedTransactions
            };

            await this.waitForInclusion(bundleInfo);

            return bundleInfo;

        } catch (error) {
            console.error("❌ 执行 Presale 失败:", error);
            throw error;
        }
    }

    /**
     * 处理检测到的 pending 交易
     * @param {string} txHash - 交易哈希
     */
    async handlePendingTransaction(txHash) {
        try {
            // 获取交易详情
            const tx = await this.wsProvider.getTransaction(txHash);

            if (!tx) {
                return; // 交易可能已被打包或丢弃
            }

            // 检查是否是目标合约的任何交易
            if (tx.to && tx.to.toLowerCase() === process.env.OPENSPACE_NFT_ADDRESS.toLowerCase()) {
                this.monitoringState.targetContractTxCount++;

                // 打印每个目标合约交易
                console.log(`\n📝 [Pending] 检测到目标合约交易 (第${this.monitoringState.targetContractTxCount}个)`);
                console.log("   交易哈希:", txHash);
                console.log("   函数选择器:", tx.data ? tx.data.slice(0, 10) : "0x");
                console.log("   发送者:", tx.from);
                console.log("   完整数据:", tx.data);

                // 检查是否是 enablePresale 交易
                if (this.isEnablePresaleTransaction(tx)) {
                    this.monitoringState.detectedTxCount++;
                    this.monitoringState.lastDetectionTime = Date.now();

                    console.log("\n🎯🎯🎯 [PENDING] 检测到 enablePresale 交易!");
                    console.log("交易哈希:", txHash);
                    console.log("发送者:", tx.from);
                    console.log("Gas Price:", ethers.formatUnits(tx.gasPrice || 0n, 'gwei'), "Gwei");
                    console.log("检测次数:", this.monitoringState.detectedTxCount);
                    console.log("交易数据:", tx.data);

                    // 停止监控并执行 bundle
                    await this.stopMempoolMonitoring();
                    await this.executeBundleOnDetection(tx);
                } else {
                    console.log("   ⚠️  不是 enablePresale 交易，跳过");
                }
            }
        } catch (error) {
            // 静默处理 Infura "internal error" - 这是正常的，因为 pending 交易可能还没有完整信息
            const errorMsg = error.message || '';
            if (errorMsg.includes('internal error') ||
                errorMsg.includes('-32000') ||
                errorMsg.includes('timeout') ||
                errorMsg.includes('NOT_FOUND')) {
                // 这些是 pending 交易的正常错误，静默处理
                return;
            }
            // 其他错误也静默处理，避免日志刷屏
        }
    }

    /**
     * 停止内存池监控
     */
    async stopMempoolMonitoring() {
        if (this.monitoringState.isMonitoring) {
            this.monitoringState.isMonitoring = false;

            if (this.wsProvider) {
                this.wsProvider.removeAllListeners('pending');
            }

            if (this.monitoringTimeoutId) {
                clearTimeout(this.monitoringTimeoutId);
                this.monitoringTimeoutId = null;
            }

            if (this.statusInterval) {
                clearInterval(this.statusInterval);
                this.statusInterval = null;
            }

            if (this.pollingInterval) {
                clearInterval(this.pollingInterval);
                this.pollingInterval = null;
            }

            const elapsed = ((Date.now() - this.monitoringState.startTime) / 1000).toFixed(1);
            console.log(`🛑 内存池监控已停止 (运行 ${elapsed}秒)`);
            console.log(`📊 总计接收: ${this.monitoringState.totalPendingCount} pending 交易`);
            console.log(`📊 目标合约交易: ${this.monitoringState.targetContractTxCount}`);
        }
    }

    async sendBundle(transactions) {
        try {
            console.log("📦 发送Flashbot捆绑交易...");
            
            const currentBlock = await this.provider.getBlockNumber();
            const targetBlock = currentBlock + 1;
            
            // 签名交易
            const signedTransactions = [];
            for (const tx of transactions) {
                const signedTx = await this.signer.signTransaction(tx);
                signedTransactions.push(signedTx);
            }
            
            // 创建bundle
            // 转换成如下bundle格式
            // [
            //     { signedTransaction: "0x..." },
            //     { signedTransaction: "0x..." }
            // ]
            const bundle = signedTransactions.map(signedTransaction => ({
                signedTransaction
            }));
            
            // 发送bundle
            const bundleSubmission = this.flashbotsProvider.sendBundle(bundle, targetBlock);
            
            console.log("🎯 目标区块:", targetBlock);
            console.log("📤 Bundle已提交，等待结果...");
            
            const bundleResolution = await bundleSubmission;
            
            if ('error' in bundleResolution) {
                console.error("❌ Bundle提交失败:", bundleResolution.error);
                return null;
            }
            
            console.log("✅ Bundle提交成功!");
            console.log("Bundle Hash:", bundleResolution.bundleHash);
            
            return {
                bundleHash: bundleResolution.bundleHash,
                targetBlock: targetBlock,
                transactions: signedTransactions
            };
            
        } catch (error) {
            console.error("❌ 发送Bundle失败:", error);
            throw error;
        }
    }

    /**
     * 创建只包含 presale 交易的 bundle（监控模式）
     * @param {ethers.Transaction} detectedTx - 检测到的交易（用于 gas 价格参考）
     * @returns {Array} 交易数组
     */
    async createPresaleOnlyBundle(detectedTx = null) {
        console.log("📦 创建仅包含 Presale 的 Bundle...");

        const currentBlock = await this.provider.getBlockNumber();
        let baseFee = (await this.provider.getFeeData()).gasPrice;

        // 如果检测到交易，使用更高的 gas price
        if (detectedTx && detectedTx.gasPrice) {
            const detectedGasPrice = detectedTx.gasPrice;
            // 使用检测到交易的 gas price + 10%
            baseFee = (detectedGasPrice * 110n) / 100n;
            console.log("⚡ 使用动态 Gas Price (基于检测到的交易)");
        }

        const nonce = await this.provider.getTransactionCount(this.signer.address);

        // 创建 presale 交易
        const presaleAmount = 1;
        const presaleValue = ethers.parseEther("0.01") * BigInt(presaleAmount);
        const presaleTx = await this.nftContract.presale.populateTransaction(presaleAmount, {
            value: presaleValue
        });

        const presaleTransaction = {
            ...presaleTx,
            nonce: nonce,
            gasLimit: 150000n,
            gasPrice: (baseFee * 150n) / 100n, // 再增加 10%
            chainId: 11155111,
            value: presaleValue
        };

        console.log("📝 Presale 交易:");
        console.log("   - Nonce:", presaleTransaction.nonce);
        console.log("   - Gas Price:", ethers.formatUnits(presaleTransaction.gasPrice, 'gwei'), "Gwei");
        console.log("   - Value:", ethers.formatEther(presaleTransaction.value), "ETH");

        return [presaleTransaction];
    }

    /**
     * 检测到 enablePresale 后执行 bundle（只包含 presale 交易）
     * @param {ethers.Transaction} detectedTx - 检测到的交易
     */
    async executeBundleOnDetection(detectedTx) {
        try {
            console.log("\n🚀 执行 Bundle (监控模式)...");

            // 创建只包含 presale 的 bundle
            const transactions = await this.createPresaleOnlyBundle(detectedTx);

            // 签名交易
            const signedTransactions = [];
            for (const tx of transactions) {
                const signedTx = await this.signer.signTransaction(tx);
                signedTransactions.push(signedTx);
            }

            // 创建 bundle
            const bundle = signedTransactions.map(signedTransaction => ({
                signedTransaction
            }));

            // 发送到 Flashbots
            const currentBlock = await this.provider.getBlockNumber();
            const targetBlock = currentBlock + 1;

            console.log("🎯 目标区块:", targetBlock);
            console.log("📤 提交 Bundle 到 Flashbots...");

            const bundleSubmission = this.flashbotsProvider.sendBundle(bundle, targetBlock);
            const bundleResolution = await bundleSubmission;

            if ('error' in bundleResolution) {
                console.error("❌ Bundle 提交失败:", bundleResolution.error);
                throw new Error(bundleResolution.error.message);
            }

            console.log("✅ Bundle 提交成功!");
            console.log("Bundle Hash:", bundleResolution.bundleHash);

            // 等待包含
            const bundleInfo = {
                bundleHash: bundleResolution.bundleHash,
                targetBlock: targetBlock,
                transactions: signedTransactions
            };

            await this.waitForInclusion(bundleInfo);

            return bundleInfo;

        } catch (error) {
            console.error("❌ 执行 Bundle 失败:", error);
            throw error;
        }
    }

    async waitForInclusion(bundleInfo) {
        try {
            console.log("⏳ 等待Bundle被包含在区块中...");

            // 等待几个区块确认Bundle是否被包含
            const maxWaitBlocks = 5;
            const startBlock = bundleInfo.targetBlock;

            for (let i = 0; i < maxWaitBlocks; i++) {
                const currentBlock = await this.provider.getBlockNumber();
                console.log(`检查区块 ${currentBlock} (目标区块: ${startBlock})...`);

                if (currentBlock >= startBlock) {
                    // 检查我们的交易是否在区块中
                    const block = await this.provider.getBlock(currentBlock, true);

                    console.log("  区块交易数:", block.transactions.length);

                    // 计算我们的交易哈希
                    const bundleTxHashes = bundleInfo.transactions.map(signedTx => {
                        const hash = ethers.keccak256(signedTx);
                        console.log(`  Bundle交易哈希: ${hash}`);
                        return hash;
                    });

                    const foundTxs = [];
                    for (const tx of block.transactions) {
                        if (typeof tx === 'object' && bundleTxHashes.includes(tx.hash)) {
                            foundTxs.push(tx.hash);
                        }
                    }

                    if (foundTxs.length > 0) {
                        console.log("🎉 Bundle已被包含在区块中!");
                        console.log("区块号:", currentBlock);
                        console.log("交易哈希:", foundTxs);
                        return { success: true, blockNumber: currentBlock, txHashes: foundTxs };
                    } else {
                        console.log(`  ❌ Bundle未在区块 ${currentBlock} 中找到`);
                    }
                }

                // 等待下一个区块
                if (i < maxWaitBlocks - 1) {
                    console.log("等待下一个区块...");
                    await new Promise(resolve => setTimeout(resolve, 12000)); // Sepolia出块时间约12秒
                }
            }

            console.log("⚠️ Bundle在等待时间内未被包含");
            console.log("可能的原因:");
            console.log("  1. Gas Price 不够高，被其他 bundle 抢先");
            console.log("  2. Bundle 模拟失败（交易执行会 revert）");
            console.log("  3. 有其他竞争者也在抢这笔交易");

            // 尝试获取 bundle stats
            try {
                const stats = await this.flashbotsProvider.getBundleStats(bundleInfo.bundleHash, 1);
                console.log("📊 Bundle Stats:", JSON.stringify(stats, null, 2));
            } catch (e) {
                console.log("⚠️  无法获取 Bundle Stats:", e.message);
            }

            return { success: false };

        } catch (error) {
            console.error("❌ 等待Bundle包含时出错:", error);
            throw error;
        }
    }

    /**
     * 启动监控模式，带超时后备
     * @param {number} timeoutMs - 超时时间（毫秒），默认 5 分钟
     */
    async executeWithMonitoring(timeoutMs = 300000) {
        console.log("⏱️  启动监控模式，超时时间:", timeoutMs / 1000, "秒");

        return new Promise(async (resolve, reject) => {
            const timeoutId = setTimeout(async () => {
                console.log("\n⏰ 监控超时，切换到直接执行模式");
                await this.stopMempoolMonitoring();

                try {
                    // 后备：直接执行（如果自己是 owner）
                    const result = await this.executeDirect();
                    resolve(result);
                } catch (error) {
                    reject(error);
                }
            }, timeoutMs);

            // 保存 timeout ID 用于清理
            this.monitoringTimeoutId = timeoutId;

            // 启动监控
            await this.startMempoolMonitoring();
        });
    }

    /**
     * 直接执行模式（原有逻辑）
     */
    async executeDirect() {
        console.log("📡 执行直接模式...");

        // 检查是否是 owner
        const contractStatus = await this.checkContractStatus();
        if (!contractStatus.isOwner) {
            throw new Error("当前钱包不是合约 owner，无法执行 enablePresale");
        }

        // 创建并执行两个交易
        const transactions = await this.createBundleTransactions(true);
        const bundleInfo = await this.sendBundle(transactions);

        if (!bundleInfo) {
            throw new Error("Bundle 发送失败");
        }

        // 等待包含
        const inclusionResult = await this.waitForInclusion(bundleInfo);

        // 获取统计
        const stats = await this.getBundleStats(bundleInfo.bundleHash);

        return {
            bundleHash: bundleInfo.bundleHash,
            targetBlock: bundleInfo.targetBlock,
            included: inclusionResult.success,
            txHashes: inclusionResult.txHashes || [],
            stats: stats
        };
    }

    async getBundleStats(bundleHash) {
        try {
            console.log("📊 获取Bundle统计信息...");
            
            // 使用flashbots_getBundleStats方法
            const stats = await this.flashbotsProvider.getBundleStats(bundleHash, 1);
            
            console.log("📈 Bundle统计信息:");
            console.log(JSON.stringify(stats, null, 2));
            
            return stats;
        } catch (error) {
            console.error("❌ 获取Bundle统计信息失败:", error);
            // 如果获取统计信息失败，返回基本信息
            return {
                bundleHash: bundleHash,
                error: "无法获取详细统计信息",
                timestamp: new Date().toISOString()
            };
        }
    }
    
    async execute() {
        try {
            console.log("🚀 开始执行 Flashbot 捆绑交易任务");
            console.log("=".repeat(50));  // 修复：原来是 "*" 应该是 ".repeat()"

            // 1. 初始化 Flashbots
            await this.initFlashbots();

            // 根据模式选择执行路径
            if (this.mode === 'monitor') {
                console.log("📡 模式: 内存池监控模式");

                // 监控模式：不需要是 owner
                // 等待其他人调用 enablePresale

                // 启动监控（5分钟超时）
                const result = await this.executeWithMonitoring(300000);

                return result;

            } else {
                console.log("📡 模式: 直接执行模式");

                // 直接模式：需要是 owner
                const contractStatus = await this.checkContractStatus();

                if (!contractStatus.isOwner) {
                    throw new Error("当前钱包不是合约 owner，无法执行 enablePresale");
                }

                // 创建并执行两个交易
                const transactions = await this.createBundleTransactions(true);
                const bundleInfo = await this.sendBundle(transactions);

                if (!bundleInfo) {
                    throw new Error("Bundle 发送失败");
                }

                // 等待包含确认
                const inclusionResult = await this.waitForInclusion(bundleInfo);

                // 获取统计信息
                const stats = await this.getBundleStats(bundleInfo.bundleHash);

                // 输出最终结果
                console.log("=".repeat(50));
                console.log("🎯 任务完成！最终结果:");
                console.log("=".repeat(50));
                console.log("Bundle Hash:", bundleInfo.bundleHash);
                console.log("目标区块:", bundleInfo.targetBlock);

                if (inclusionResult.success) {
                    console.log("✅ 交易成功执行!");
                    console.log("包含区块:", inclusionResult.blockNumber);
                    console.log("交易哈希:");
                    inclusionResult.txHashes.forEach((hash, index) => {
                        console.log(`  ${index + 1}. ${hash}`);
                    });
                } else {
                    console.log("⚠️ 交易未被包含，可能需要重试");
                }

                console.log("\n📊 Bundle统计信息:");
                console.log(JSON.stringify(stats, null, 2));

                return {
                    bundleHash: bundleInfo.bundleHash,
                    targetBlock: bundleInfo.targetBlock,
                    included: inclusionResult.success,
                    txHashes: inclusionResult.txHashes || [],
                    stats: stats
                };
            }

        } catch (error) {
            console.error("❌ 执行失败:", error);
            throw error;
        } finally {
            // 清理监控资源
            await this.stopMempoolMonitoring();
        }
    }
}

// 主函数
async function main() {
    try {
        // 从环境变量读取执行模式
        const mode = process.env.EXECUTION_MODE || 'direct';
        console.log("启动模式:", mode);

        const executor = new FlashbotBundleExecutor(mode);
        const result = await executor.execute();

        console.log("\n🎉 所有任务完成!");
        console.log("最终结果已保存，请查看上方输出。");
    } catch (error) {
        console.error("💥 程序执行失败:", error.message);
        process.exit(1);
    }
}

main()