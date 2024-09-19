// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/18_MagicNumber.sol";

contract ExploitScript is Script {
    MagicNum level18 = MagicNum(payable(your_challenge_address));
    
    function run() external {
        vm.startBroadcast();
        level18.setSolver(address(new MagicNumAttack()));
        vm.stopBroadcast();
    }
}

contract MagicNumAttack {
  
  constructor() {
    assembly {
      mstore(0, 0x602a60005260206000f3)
      return(22, 0x0a)
    }
  }
}