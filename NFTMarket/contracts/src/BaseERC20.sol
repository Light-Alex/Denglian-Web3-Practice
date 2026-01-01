// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ITokenReceiver
 * @notice Interface for contracts that want to receive token callbacks
 */
interface ITokenReceiver {
    function tokensReceived(
        address from,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

/**
 * @title BaseERC20
 * @notice Extended ERC20 token with callback functionality
 * @dev Implements transferWithCallback for hook-based transfers
 */
contract BaseERC20 is ERC20, Ownable {

    event TransferWithCallback(
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data
    );

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    /**
     * @notice Transfer tokens with callback functionality
     * @dev If recipient is a contract, calls tokensReceived() hook
     * @param to Recipient address
     * @param amount Amount of tokens to transfer
     * @param data Additional data to pass to the callback
     * @return bool Success status
     */
    function transferWithCallback(
        address to,
        uint256 amount,
        bytes calldata data
    ) external returns (bool) {
        require(to != address(0), "Transfer to zero address");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        // Perform the transfer
        _transfer(msg.sender, to, amount);

        // If recipient is a contract, call the callback
        if (_isContract(to)) {
            require(
                ITokenReceiver(to).tokensReceived(msg.sender, amount, data),
                "Callback failed"
            );
        }

        emit TransferWithCallback(msg.sender, to, amount, data);

        return true;
    }

    /**
     * @notice Check if an address is a contract
     * @param account Address to check
     * @return bool True if account is a contract
     */
    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @notice Mint new tokens (only owner)
     * @param to Recipient address
     * @param amount Amount to mint
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
