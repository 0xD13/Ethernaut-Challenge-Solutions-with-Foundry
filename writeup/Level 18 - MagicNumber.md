# Level 18 - MagicNumber
## 題目
[MagicNumber](https://ethernaut.openzeppelin.com/level/0x2132C7bc11De7A90B87375f282d36100a29f97a9)

### 通關條件
要解決這個關卡，您只需向 Ethernaut 提供一個合約Solver，該合約 `whatIsTheMeaningOfLife()` 以正確的 32 位元組數字回應。
容易吧？嗯...有個問題。
求解器的程式碼必須非常小。真的很小。就像真的非常非常小：最多 10 bytes。
提示：也許是時候暫時離開 Solidity 編譯器的舒適感，並手動建立這個編譯器了 O_o。沒錯：原始 EVM bytes。

祝你好運！
### 合約內容
```solidity=
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MagicNum {
    address public solver;

    constructor() {}

    function setSolver(address _solver) public {
        solver = _solver;
    }

    /*
    ____________/\\\_______/\\\\\\\\\_____        
     __________/\\\\\_____/\\\///////\\\___       
      ________/\\\/\\\____\///______\//\\\__      
       ______/\\\/\/\\\______________/\\\/___     
        ____/\\\/__\/\\\___________/\\\//_____    
         __/\\\\\\\\\\\\\\\\_____/\\\//________   
          _\///////////\\\//____/\\\/___________  
           ___________\/\\\_____/\\\\\\\\\\\\\\\_ 
            ___________\///_____\///////////////__
    */
}
```
## 解題
這一題牽扯到比較多底層的知識，必須要透過 opcode 完成。
題目要求建造一個合約，會回傳 `42` 這個數字，而且程式碼要在 10 bytes 完成。要完成的方法就是自己寫 opcode；若透過寫 Solidity 的方式，在編譯的過程中，會把程式進入點、函式判斷都編譯進去 byte code 裡面，超過 10 bytes。
所以我們要自己寫一個合約，在部署的時候就會自動以 opcode 的方式寫入一個「回傳 42」的功能。

關於底層 EVM 可以參考 
- [以太坊虛擬機 (The Ethereum Virtual Machine)](https://cypherpunks-core.github.io/ethereumbook_zh/14.html) 
- [An Ethereum Virtual Machine Opcodes Interactive Reference](https://www.evm.codes/)

關於合約在部署時的流程可以參考 
- [Deconstructing a Solidity Contract — Part II: Creation vs. Runtime
](https://medium.com/zeppelin-blog/deconstructing-a-solidity-contract-part-ii-creation-vs-runtime-6b9d60ecb44c)
- [Level 14 - Gatekeeper Two](https://hackmd.io/@D13/ethernaut14)


---
要實現「回傳 42」，會用到以下三個 opcode：

| Opcode | Name | Description |Stack Input|
| -------- | -------- | -------- |---|
| 60     | push     | 	Place 1 byte item on stack     |
| 52     | mstore     | 	Save word to memory     |offset, value|
| F3     | return     | 	Halt execution returning output data    |offset, size|

`mstore(value, position)`，把 `value` 放到指定的位置，用於儲存題目指定的數字「42」：
```
PUSH1 0x2a
PUSH1 0x00
MSTORE 
```

`return(offset, size)`，回傳指定的記憶體位置：
```
PUSH1 0x20
PUSH1 0x00
RETURN
```
組合起來，達成「回傳42」的功能，長度剛好 10 bytes：
```
602a60005260206000f3
```
所以只要將這段 bytecode 寫入合約的 runtime 區域即可
在 `constructor()` 中透過 `mstore(value, position)` 寫入，再用 `return(offset, size)` 。攻擊如下：
```solidity
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
```