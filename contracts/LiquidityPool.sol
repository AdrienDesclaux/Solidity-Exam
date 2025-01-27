// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LPToken.sol";

contract LiquidityPool is LPtoken {
    address public token0;
    address public token1;
    address public factory;
    uint8 public swapFee;
    uint112 private reserve0;
    uint112 private reserve1; 

    event AddLiquidity(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to);

    error IdenticalTokens();
    error InsufficientLiquidity();
    error InsufficientInputAmount();
    error InsufficientOutputAmount();
    error TransferFailed();

    constructor(address _token0, address _token1, uint8 _swapFee, string memory name, string memory symbol) LPtoken(name, symbol, address(this)) {
        factory = msg.sender;
        if (_token0 == _token1) revert IdenticalTokens();
        token0 = _token0;
        token1 = _token1;
        swapFee = _swapFee;

        // Deploy a new LPtoken
        new LPtoken(name, symbol, address(this));
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }

    function _update(uint balance0, uint balance1) private returns (bool) {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, "Overflow");
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        return true;
    }

    function addLiquidity(address to) external returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1) = getReserves();
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0 - _reserve0;
        uint amount1 = balance1 - _reserve1;

        // returns the totalSupply of the LPtoken
        uint totalSupply = totalSupply();   
        if (totalSupply == 0) {
            liquidity = sqrt(amount0 * amount1);
        } else {
            liquidity = min(amount0 * totalSupply / _reserve0, amount1 * totalSupply / _reserve1);
        }
        if (liquidity == 0) revert InsufficientLiquidity();
        
        mintLP(to, liquidity);

        _update(balance0, balance1);
        emit AddLiquidity(msg.sender, amount0, amount1);
    }

    function removeLiquidity(address to) external returns (uint amount0, uint amount1) {
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint liquidity = balanceOf(address(this));
        uint totalSupply = totalSupply();

        amount0 = liquidity * balance0 / totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity * balance1 / totalSupply; // using balances ensures pro-rata distribution
        if (amount0 == 0 || amount1 == 0) revert InsufficientLiquidity();
        
        totalSupply -= liquidity;
        burnLP(msg.sender, liquidity);
        payable(to).transfer(amount0);
        payable(to).transfer(amount1);


        _update(balance0 - amount0, balance1 - amount1);
        emit Burn(msg.sender, amount0, amount1, to);
    }

    function swap(uint amount0Out, uint amount1Out, address to) external {
        if (amount0Out == 0 && amount1Out == 0) revert InsufficientOutputAmount();
        (uint112 _reserve0, uint112 _reserve1) = getReserves(); // gas savings
        if (amount0Out > _reserve0 || amount1Out > _reserve1) revert InsufficientLiquidity();

        uint balance0;
        uint balance1;

            if (amount0Out > 0) payable(to).transfer(amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) payable(to).transfer(amount1Out); // optimistically transfer tokens
            balance0 = IERC20(token0).balanceOf(address(this));
            balance1 = IERC20(token1).balanceOf(address(this));

        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        if (amount0In == 0 && amount1In == 0) revert InsufficientInputAmount();

        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint balance0Adjusted = balance0 * 1000 - amount0In * 3;
            uint balance1Adjusted = balance1 * 1000 - amount1In * 3;
            if (balance0Adjusted * balance1Adjusted < uint(_reserve0) * uint(_reserve1) * (1000**2)) revert InsufficientLiquidity();
        }

        _update(balance0, balance1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }
}
