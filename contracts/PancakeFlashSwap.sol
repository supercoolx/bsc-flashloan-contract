//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.6;

// Uniswap interface and library imports
import "./interface/IUniswapV2Pair.sol";
import "./interface/IUniswapV2Factory.sol";
import "./interface/IERC20.sol";

contract PancakeFlashSwap {
    address private constant PANCAKE_FACTORY = 0x6725F303b657a9451d8BA641348b6761A6CC7a17;
    address private constant PANCAKE_ROUTER = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;

    address private constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address private constant BUSD = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee;

    struct Call {
        address to;
        bytes data;
    }

    // Initiate arbtrage
    // begins receving loan to engage and performing arbtrage trades
    function flashloan(address loanAsset, uint256 loanAmount, Call[] memory calls) external {
        // Get the Factory Pair address for combined tokens
        address otherAsset = loanAsset == WBNB ? BUSD : WBNB;
        address pair = IUniswapV2Factory(PANCAKE_FACTORY).getPair(loanAsset, otherAsset);

        // Return error if combination does not exit
        require(pair != address(0), "Pool does not exist");
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        uint256 amount0Out = loanAsset == token0 ? loanAmount : 0;
        uint256 amount1Out = loanAsset == token1 ? loanAmount : 0;

        bytes memory data = abi.encode(loanAsset, loanAmount, msg.sender, calls);

        // Execute the initial swap to get the loan
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
    }

    function pancakeCall(address _sender, uint256 , uint256 , bytes calldata data) external {
        // Ensure this request cane from the contract
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        address pair = IUniswapV2Factory(PANCAKE_FACTORY).getPair(token0, token1);

        require(msg.sender == pair, "The sender needs to match the pair contract");
        require(_sender == address(this), "Sender should match this contract");

        (address loanAsset, uint256 loanAmount, address payer, Call[] memory calls) = abi.decode(data, (address, uint256, address, Call[]));

        for (uint i = 0; i < calls.length; i++) {
            (bool success,) = calls[i].to.call(calls[i].data);
            require(success, "Swap Failed");
        }

        uint256 fee = ((loanAmount * 3) / 997) + 1;
        uint256 amountToRepay = loanAmount + fee;
        IERC20(loanAsset).transfer(pair, amountToRepay);

        uint256 balance = IERC20(loanAsset).balanceOf(address(this));
        IERC20(loanAsset).transfer(payer, balance);
    }

}