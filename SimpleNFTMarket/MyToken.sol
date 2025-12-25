//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface TokenRecipient {
    function tokensReceived(address _token, uint256 _amount, bytes calldata data) external returns (bool);
}

contract MyERC20Callback is ERC20 {
    constructor() ERC20("CXERC20", "CXB") {
        _mint(msg.sender, 1000 * 10 ** decimals());
    }

    // 方式二：用户直接给NFT Market合约转账，带上tokenId，用于购买NFT
    function transferWithCallback(address _to, uint256 _amount, bytes calldata data) external returns (bool) {
        _transfer(msg.sender, _to, _amount);

        if (_to.code.length > 0) {
            require(TokenRecipient(_to).tokensReceived(msg.sender, _amount, data), "transferWithCallback: transfer failed");
        }

        return true;
    }

    function transferFromWithCallback(address _from, address _to, uint256 _amount, bytes calldata data) external returns (bool) {
        // 授权校验
        _spendAllowance(_from, msg.sender, _amount);
        _transfer(_from, _to, _amount);

        if (_to.code.length > 0) {
            require(TokenRecipient(_to).tokensReceived(_from, _amount, data), "transferFromWithCallback: transfer failed");
        }

        return true;
    }
    
}