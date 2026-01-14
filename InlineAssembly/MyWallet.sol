// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract MyWallet { 
    string public name;
    mapping (address => bool) private approved;
    address public owner;

    modifier auth {
        // require (msg.sender == owner, "Not authorized");

        // 使用内联汇编方式获取owner的值
        assembly {
            let ownerAddr := sload(owner.slot)
            if iszero(eq(ownerAddr, caller())) {
                mstore(0x00, "Not authorized")

                // 从内存地址0x00开始，返回32字节数据
                revert(0x00, 0x20)
            }
        }
        _;
    }

    constructor(string memory _name) {
        name = _name;
        owner = msg.sender;
    } 

    function transferOwernship(address _addr) auth public {
        // require(_addr!=address(0), "New owner is the zero address");
        // require(owner != _addr, "New owner is the same as the old owner");
        // owner = _addr;

        // 使用内联汇编方式设置owner的值
        assembly {
            // 检查新地址是否为0地址
            if iszero(_addr) {
                mstore(0x00, "New owner is the zero address")
                revert(0x00, 0x20)
            }

            let ownerAddr := sload(owner.slot)
            // 检查新地址是否与旧地址相同
            if eq(_addr, ownerAddr) {
                mstore(0x00, "New owner is the same")
                revert(0x00, 0x20)
            }

            sstore(owner.slot, _addr)
        }
    }
}