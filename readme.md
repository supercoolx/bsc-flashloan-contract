# Binance smart chain flashloan arbitrage bot (AlmaZeus)

Flashswaps contract using Pancakeswap on BSC network.

## How to use

- First, you must install truffle.
    ```
    npm intall -g truffle

    truffle version
        Truffle v5.5.6 (core: 5.5.6)
        Ganache v^7.0.3
        Solidity v0.5.16 (solc-js)
        Node v16.11.0
        Web3.js v1.5.3
    ```


1. Install node_modules
    ```
    npm install
    ```
2. Rename `.env.example` file to `.env`.
3. Config `.env` file.

    You need to use private key of your wallet.

    You can get `BSCSCAN_KEY` on [bscscan.com](https://bscscan.com).

4. Deploy contract.

    - Testnet
        ```
        npm start
        ```

5. Verify contract.

    - Testnet
        ```
        npm run verify
        ```

## Important

If you want to deploy contract on mainnet, You must change some addresses on `PancakeFlashSwap.sol`.

```solidity

contract PancakeFlashSwap {
    address private constant PANCAKE_FACTORY = 0x6725F303b657a9451d8BA641348b6761A6CC7a17;
    address private constant PANCAKE_ROUTER = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;

    address private constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address private constant BUSD = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee;

}

```
