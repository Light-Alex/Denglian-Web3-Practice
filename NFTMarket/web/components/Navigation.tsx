'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useAccount, useConnect } from 'wagmi';

const navLinks = [
  { href: '/', label: 'NFT Market' },
  { href: '/transactions', label: 'Transaction History' },
  { href: '/myerc20', label: 'ERC20 Token' },
  { href: '/mynft', label: 'My NFT' },
];

export function Navigation() {
  const pathname = usePathname();
  const { isConnected, address } = useAccount();
  const { connect, connectors, isPending } = useConnect();

  console.log('Connection Status:', {
    isConnected,
    address,
    isPending,
    connectors: connectors.map(c => c.name)
  });

  return (
    <nav className="bg-white border-b border-gray-200 shadow-sm">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-16">
          <div className="flex space-x-8">
            {navLinks.map((link) => {
              const isActive = pathname === link.href;
              return (
                <Link
                  key={link.href}
                  href={link.href}
                  className={`inline-flex items-center px-1 pt-1 text-sm font-medium transition-colors ${
                    isActive
                      ? 'text-blue-600 border-b-2 border-blue-600'
                      : 'text-gray-600 hover:text-gray-900 hover:border-b-2 hover:border-gray-300'
                  }`}
                >
                  {link.label}
                </Link>
              );
            })}
          </div>

          <div className="flex items-center space-x-4">
            {/* 显示连接状态信息 */}
            {isConnected && address && (
              <div className="text-sm text-gray-600">
                已连接: {address}
              </div>
            )}
            {isPending && (
              <div className="text-sm text-yellow-600">
                连接中...
              </div>
            )}
            <appkit-button />
          </div>
        </div>
      </div>
    </nav>
  );
}