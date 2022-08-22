//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.6;

// Uniswap interface and library imports
import "./interface/IUniswapV2Pair.sol";
import "./interface/IUniswapV2Factory.sol";
import "./interface/IUniswapV2Router.sol";
import "./interface/IERC20.sol";

contract PancakeFlashSwap {
    uint private constant deadline = 10 days;
    address private constant PANCAKE_FACTORY = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;

    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    address[] private routers;
    address[] private tokens;

    struct Call {
        address to;
        bytes data;
    }

    function addRouters(address[] memory _routers) external {
        for (uint i; i < _routers.length; i++) {
            routers.push(_routers[i]);
        }
    }

    function getRouters() external view returns (address[] memory) {
        return routers;
    }

    function addTokens(address[] memory _tokens) external {
        for (uint i; i < _tokens.length; i++) {
            tokens.push(_tokens[i]);
        }
    }

    function getTokens() external view returns (address[] memory) {
        return tokens;
    }

    function getAmountOut(address _router, address _tokenIn, address _tokenOut, uint _amountIn) public view returns (uint) {
        address[] memory path = new address[](2);
        (path[0], path[1]) = (_tokenIn, _tokenOut);
        try IUniswapV2Router(_router).getAmountsOut(_amountIn, path) returns (uint[] memory amounts) {
            return amounts[1];
        } catch {
            return 0;
        }
    }

    function search(uint amountIn, address[] memory path) external view returns (uint[] memory amounts) {
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            uint maxAmountOut = 0;
            for (uint j; j < routers.length; j++) {
                uint amountOut = getAmountOut(routers[j], path[i], path[i + 1], amounts[i + 1]);
                if (maxAmountOut < amountOut) maxAmountOut = amountOut;
            }
            amounts[i + 1] = maxAmountOut;
        }
    }

    // Initiate arbtrage
    // begins receving loan to engage and performing arbtrage trades
    function flashloan(address loanAsset, uint loanAmount, Call[] memory calls) external {
        // Get the Factory Pair address for combined tokens
        address otherAsset = loanAsset == WBNB ? BUSD : WBNB;
        address pair = IUniswapV2Factory(PANCAKE_FACTORY).getPair(loanAsset, otherAsset);

        // Return error if combination does not exit
        require(pair != address(0), "Pool does not exist");
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        uint amount0Out = loanAsset == token0 ? loanAmount : 0;
        uint amount1Out = loanAsset == token1 ? loanAmount : 0;

        bytes memory data = abi.encode(loanAsset, loanAmount, msg.sender, calls);

        // Execute the initial swap to get the loan
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
    }

    function pancakeCall(address _sender, uint, uint, bytes calldata data) external {
        // Ensure this request cane from the contract
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        address pair = IUniswapV2Factory(PANCAKE_FACTORY).getPair(token0, token1);

        require(msg.sender == pair, "The sender needs to match the pair contract");
        require(_sender == address(this), "Sender should match this contract");

        (
            address loanAsset,
            uint loanAmount,
            address payer,
            Call[] memory calls
        ) = abi.decode(data, (address, uint, address, Call[]));

        for (uint i; i < calls.length; i++) {
            (bool success, ) = calls[i].to.call(calls[i].data);
            require(success, "Swap Failed");
        }

        uint fee = ((loanAmount * 3) / 997) + 1;
        uint amountToRepay = loanAmount + fee;
        IERC20(loanAsset).transfer(pair, amountToRepay);

        uint balance = IERC20(loanAsset).balanceOf(address(this));
        IERC20(loanAsset).transfer(payer, balance);
    }
}
