import Link from 'next/link'

export default function Home() {
  return (
    <div className="container py-16">
      <div className="max-w-4xl mx-auto">
        <div className="text-center mb-12">
          <div className="text-6xl mb-6">🚀</div>
          <h1 className="text-5xl font-bold tracking-tight mb-4 bg-gradient-to-r from-blue-600 to-violet-600 bg-clip-text text-transparent">
            Token LaunchPad
          </h1>
          <p className="text-xl text-muted-foreground mb-8">
            去中心化代币发行平台，轻松发起和参与代币销售
          </p>
        </div>

        <div className="grid gap-6 md:grid-cols-2 mb-12">
          {/* 核心功能 */}
          <div className="bg-gradient-to-br from-blue-50 to-violet-50 rounded-lg p-6">
            <h2 className="text-2xl font-bold mb-4 flex items-center gap-2">
              <span>🎯</span>
              核心功能
            </h2>
            <ul className="space-y-3 text-muted-foreground">
              <li className="flex items-start gap-2">
                <span className="text-green-600 mt-1">✓</span>
                <span>创建代币销售活动</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="text-green-600 mt-1">✓</span>
                <span>设置灵活的销售参数（价格、数量、时间）</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="text-green-600 mt-1">✓</span>
                <span>使用 USDC 购买代币</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="text-green-600 mt-1">✓</span>
                <span>实时销售进度追踪</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="text-green-600 mt-1">✓</span>
                <span>销售结束后一键领取代币</span>
              </li>
            </ul>
          </div>

          {/* 技术特点 */}
          <div className="bg-white rounded-lg border p-6">
            <h2 className="text-2xl font-bold mb-4 flex items-center gap-2">
              <span>⚡</span>
              技术特点
            </h2>
            <ul className="space-y-3 text-muted-foreground">
              <li className="flex items-start gap-2">
                <span className="text-blue-600 mt-1">●</span>
                <span>基于 Foundry 开发，安全可靠</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="text-blue-600 mt-1">●</span>
                <span>EIP-1167 最小代理模式，节省 Gas</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="text-blue-600 mt-1">●</span>
                <span>完整的前端集成，用户体验流畅</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="text-blue-600 mt-1">●</span>
                <span>支持多个项目同时销售</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="text-blue-600 mt-1">●</span>
                <span>OpenZeppelin 合约库保障安全</span>
              </li>
            </ul>
          </div>
        </div>

        {/* 操作指南 */}
        <div className="bg-gradient-to-r from-blue-100 to-violet-100 rounded-lg p-8 mb-12">
          <h2 className="text-2xl font-bold mb-6 text-center">如何使用</h2>
          <div className="grid gap-6 md:grid-cols-3">
            <div className="text-center">
              <div className="text-4xl mb-3">1️⃣</div>
              <h3 className="font-semibold mb-2">连接钱包</h3>
              <p className="text-sm text-muted-foreground">
                使用 MetaMask 或其他 Web3 钱包连接到 Sepolia 测试网
              </p>
            </div>
            <div className="text-center">
              <div className="text-4xl mb-3">2️⃣</div>
              <h3 className="font-semibold mb-2">浏览项目</h3>
              <p className="text-sm text-muted-foreground">
                查看正在进行的代币销售项目，选择感兴趣的项目
              </p>
            </div>
            <div className="text-center">
              <div className="text-4xl mb-3">3️⃣</div>
              <h3 className="font-semibold mb-2">参与购买</h3>
              <p className="text-sm text-muted-foreground">
                使用 USDC 购买代币，销售结束后领取你的代币
              </p>
            </div>
          </div>
        </div>

        {/* CTA 按钮 */}
        <div className="flex flex-col sm:flex-row gap-4 justify-center">
          <Link
            href="/launchpad"
            className="inline-flex items-center justify-center rounded-lg bg-gradient-to-r from-blue-600 to-violet-600 px-8 py-4 text-lg font-semibold text-white hover:opacity-90 transition-opacity"
          >
            浏览项目 →
          </Link>
          <Link
            href="/launchpad/create"
            className="inline-flex items-center justify-center rounded-lg border-2 border-blue-600 px-8 py-4 text-lg font-semibold text-blue-600 hover:bg-blue-50 transition-colors"
          >
            创建销售
          </Link>
        </div>

        {/* 合约信息 */}
        <div className="mt-16 pt-8 border-t">
          <h3 className="text-lg font-semibold mb-4 text-center">已部署合约</h3>
          <div className="grid gap-4 md:grid-cols-2 text-sm">
            <div className="bg-white rounded-lg border p-4">
              <div className="font-semibold text-blue-600 mb-2">LaunchPadV2</div>
              <div className="text-muted-foreground font-mono text-xs break-all">
                0x0CfF6fe40c8c2c15930BFce84d27904D8a8461Cf
              </div>
            </div>
            <div className="bg-white rounded-lg border p-4">
              <div className="font-semibold text-violet-600 mb-2">Payment Token (USDC)</div>
              <div className="text-muted-foreground font-mono text-xs break-all">
                0x2d6BF73e7C3c48Ce8459468604fd52303A543dcD
              </div>
            </div>
          </div>
          <p className="text-center text-sm text-muted-foreground mt-4">
            部署在 Sepolia 测试网
          </p>
        </div>
      </div>
    </div>
  )
}

