// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Counter {
    uint256 public count;

    constructor(){
        count = 0;
    }

    function get() public view returns (uint256) {
        return count;
    }

    function add(uint256 x) public {
        count += x;
    }
}
