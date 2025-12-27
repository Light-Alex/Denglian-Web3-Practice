// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface TokenRecipient {
    function tokensReceived(address _token, uint256 _amount, bytes calldata data) external returns (bool);
}

contract MyToken is ERC20 { 
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _mint(msg.sender, 1e10*1e18);
    }

    function transferWithCallback(address _to, uint256 _amount, bytes calldata data) external returns (bool) {
        _transfer(msg.sender, _to, _amount);

        if (_to.code.length > 0) {
            require(TokenRecipient(_to).tokensReceived(msg.sender, _amount, data), "transferWithCallback: transfer failed");
        }

        return true;
    }
}