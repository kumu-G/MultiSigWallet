// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";

contract MultiSigWalletScript is Script {
    MultiSigWallet public msw;

    address[] public owners;
    uint256 public threshold = 1;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAccountAddress = vm.envAddress("ACCOUNT_ADDRESS");
        address deployerAddress = vm.addr(deployerPrivateKey);
        owners = [deployerAddress, deployerAccountAddress];
        vm.startBroadcast(deployerPrivateKey);

        msw = new MultiSigWallet(owners, threshold);
        console.log("MultiSigWallet deployed to:", address(msw));

        vm.stopBroadcast();
    }
}
