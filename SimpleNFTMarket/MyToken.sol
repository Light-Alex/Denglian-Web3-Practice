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

    function transferFromWithCallback(address _from, address _to, uint256 _amount, bytes calldata data) external returns (bool) {
        _transfer(_from, _to, _amount);

        if (_to.code.length > 0) {
            require(TokenRecipient(_to).tokensReceived(_from, _amount, data), "transferFromWithCallback: transfer failed");
        }

        return true;
    }
    
}