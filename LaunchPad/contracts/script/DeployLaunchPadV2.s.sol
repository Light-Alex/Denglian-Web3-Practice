// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseScript.s.sol";
import "../src/PaymentToken.sol";
import "../src/LaunchPadV2.sol";

contract DeployLaunchPadV2 is BaseScript {
    function run() public broadcaster {
        // Read private key from environment
        console.log("Deployer address:", deployer);

        // Deploy payment token
        PaymentToken paymentToken = new PaymentToken();
        saveContract(getNetworkName(block.chainid), "PaymentToken", address(paymentToken));
        console.log("PaymentToken deployed at:", address(paymentToken));

        // Deploy TokenFactory
        TokenFactory tokenFactory = new TokenFactory();
        saveContract(getNetworkName(block.chainid), "TokenFactory", address(tokenFactory));
        console.log("TokenFactory deployed at:", address(tokenFactory));

        // Deploy LaunchPadV2
        LaunchPadV2 launchpad = new LaunchPadV2(address(tokenFactory));
        saveContract(getNetworkName(block.chainid), "LaunchPadV2", address(launchpad));
        console.log("LaunchPadV2 deployed at:", address(launchpad));
    }
}