# Level 0 - Hello Ethernaut
## 題目
[Hello Ethernaut](https://ethernaut.openzeppelin.com/level/0x7E0f53981657345B31C59aC44e9c21631Ce710c7)


這一關可以幫助你初步了解這個遊戲要怎麼玩。
1. 設定 Metamask
如果你還沒有安裝 Metamask，可以去 Metamask browser extension 安裝 (適用於桌面Chrome，Firefox，Brave 或者 Opera)。 設定好 Metamask 的錢包，並且在 Metamask 界面的左上方選擇「Rinkeby test network」測試網。
2. 打開瀏覽器的控制台
打開瀏覽器控制台: `Tools > Developer Tools`  
你應該可以看到一些關於遊戲的訊息，其中一個是你的「玩家地址」。這地址在遊戲中很重要，你可以在控制台輸入以下指令查看你的玩家地址：  
`player`  
請注意警告和錯誤，因為它們可能在遊戲進行中提供了有關遊戲的重要訊息。
3. 使用控制台輔助指令
你可以透過以下指令來得知你當下的賬戶餘額：
`getBalance(player)`
**NOTE: 展開 promise 可以看到真實數值，即使它顯示的是 "pending". 如果你使用的是 Chrome v62，你可以使用 `await getBalance(player)` 會呈現更乾淨的使用體驗。**
讚啦！如果想要知道更多輔助指令可以在控制台輸入下面指令：
`help()`
這在遊戲中超有用的喔。
4. ethernaut 合約
在控制台中輸入以下指令：
`ethernaut`
這是這個遊戲的主合約，你不需要透過控制台和它直接互動(因為這個網頁/應用程式已經幫你做好了)，但是如果你想要的話，你還是可以跟他直接互動。現在先試玩看看這個合約，應該是一個讓你了解如何和遊戲裡其它合約互動的好方法。
然後讓我們來展開 ethernaut 看看裡面有什麼。
5. 和 ABI 互動
`ethernaut` 是一個 `TruffleContract` 物件， 它包裝了部署在區塊鏈上的 `Ethernaut.sol` 合約。
除此之外，合約的 ABI 還提供了所有的 `Ethernaut.sol` 公開方法(public methods)，比如說 `owner`. 試試看輸入以下指令：
`ethernaut.owner()`
如果你使用的是 Chrome v62，可以使用 `await ethernaut.owner()`
你可以看到這個 ethernaut 合約的擁有者是誰，不過當然不是你，ㄏㄏ (σﾟ∀ﾟ)σ。
6. 獲得測試網 ether
為了玩這個遊戲，你需要一些 ether。最簡單可以拿到測試網 ether 的方法是透過 [this](https://faucet.rinkeby.io/)，[this](https://faucets.chain.link/rinkeby) 或 [this faucet](https://faucet.paradigm.xyz/)。
一旦你在你的餘額中有一些 ether 之後，就可以進行下一步。
7. 獲得這個關卡實例
當你再玩一個關卡的時候，你其實不是直接和 ethernaut 合約互動。而是請求 ethernaut 合約產生一個 關卡實例 (level instance) .為了取得關卡實例，你需要點擊頁面下方的藍色按鈕。現在快過去按他，然後再回來！  
Metamask 會跳出要求你給該筆交易授權。授權過後，你會在控制台看到一些訊息。注意喔！這是在區塊鏈上部署一個新的合約，所以可能需要花一些時間，因此請耐心等待一下吧！
8. 檢查合約
就像你剛才和 ethernaut 合約互動的那樣，你可以透過控制台輸入 `contract` 變數來檢查這個合約的 ABI。
9. 和這個合約互動來完成關卡
來看看這個關卡合約的 info 方法
`contract.info()`
**如果你使用的是 Chrome v62，可以使用 `await contract.info()`**
### 通關條件
你應該已經在合約裡面找到所有你破關所需的資料和工具了。當你覺得你已經完成了這關，按一下這個頁面的橘色按鈕就可以提交合約。這會將你的實例發送回給 ethernaut， 然後就可以用來判斷你是否完成了任務。
小提示: 別忘了你什麼時候都可以查看合約的 ABI 喔！
## 解題
題目一開始會先介紹一下怎麼用瀏覽器的網頁開發者工具跟合約互動，和怎麼啟動關卡實例。等啟動後就可以透過 `contract.abi()` 觀看合約的 function，如下：
![abi](/writeup/img/0_abi.png)

>[!Tip]
>ABI (Application Binary Interface) 定義函式的介面，包含輸入輸出、函式讀寫狀態等，可以幫助開發者了解怎麼跟這支合約互動。
>詳細欄位說明可以參考：[ABI-function-fields.md](https://gist.github.com/Ankarrr/899e914701233cc4ddb26f211c2a1731#file-abi-function-fields-md)

題目要求先從 `contract.info()` 開始，呼叫後發現會給你下一個要呼叫的提示，一路跟著提示呼叫 function 就可以過關了。這裡不贅述，附上解題的過程（Chrome Develope Tools）：
```javascript
› await contract.info()
‹ 'You will find what you need in infol().'
› await contract.info1()
‹ 'Try info2(), but with "hello" as a parameter.'
› await contract. info2("hello")
« 'The property infoNum holds the number of the next info method to call.'
› await contract. infoNum ()
‹ { negative: 0, 
    words: [42], 
    length: 1, 
    red: null
  }
› await contract.info42()
« 'theMethodName is the name of the next method.'
› await contract. theMethodName ( )
« 'The method name is method7123949.'
› await contract.method7123949()
‹ 'If you know the password, submit it to authenticate().'
› await contract.password ()
« 'ethernauto'
› await contract.authenticate('ethernauto')
```
提交之後，等待一下就會通知過關了。成功後會秀出這支合約的原始碼。
### 題目合約
``` solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Instance {
    string public password;
    uint8 public infoNum = 42;
    string public theMethodName = "The method name is method7123949.";
    bool private cleared = false;

    // constructor
    constructor(string memory _password) {
        password = _password;
    }

    function info() public pure returns (string memory) {
        return "You will find what you need in info1().";
    }

    function info1() public pure returns (string memory) {
        return 'Try info2(), but with "hello" as a parameter.';
    }

    function info2(string memory param) public pure returns (string memory) {
        if (keccak256(abi.encodePacked(param)) == keccak256(abi.encodePacked("hello"))) {
            return "The property infoNum holds the number of the next info method to call.";
        }
        return "Wrong parameter.";
    }

    function info42() public pure returns (string memory) {
        return "theMethodName is the name of the next method.";
    }

    function method7123949() public pure returns (string memory) {
        return "If you know the password, submit it to authenticate().";
    }

    function authenticate(string memory passkey) public {
        if (keccak256(abi.encodePacked(passkey)) == keccak256(abi.encodePacked(password))) {
            cleared = true;
        }
    }

    function getCleared() public view returns (bool) {
        return cleared;
    }
}
```
review 一下題目合約，在第 5 行可以發現 `password` 一開始並未被賦值，直到合約被實例化的時候才會由創建者輸入（11-13 行）  
38-42 行判斷我們最後提交的密碼是否正確，其他解題時呼叫的 function 也都可以在程式碼中找到。這裡還有一個觀念，**Solidity 的變數在宣告時若是屬於 public 的狀態，會自動生成一個 getter function**，讓任何人都可以透過這個 function 取得該變數的值，這也是為什麼在原始碼中看不到 `password()` 這個 function 但是 ABI 中會有的關係。關於 Solidity 的變數讀取狀態可以參考這篇：[[EN] Learn Solidity lesson 2. Public variables.
](https://medium.com/coinmonks/learn-solidity-lesson-2-public-variables-2f79389a3a44)

