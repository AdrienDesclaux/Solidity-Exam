// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./LPToken.sol";

contract LiquidityPool is ReentrancyGuard, LPToken {
    address public token0;
    address public token1;
    address public factory;
    uint8 public constant SWAP_FEE = 2;
    uint112 private reserve0;
    uint112 private reserve1;
    uint private lpFeeAccumulator0;
    uint private lpFeeAccumulator1;
    address public treasury;
    LPToken public lpToken;
    uint private unlocked = 1;

    modifier lock() {
        if (unlocked == 0) revert Locked();
        unlocked = 0;
        _;
        unlocked = 1;
    }

    event AddLiquidity(address indexed sender, uint amount0, uint amount1);
    event RemoveLiquidity(address indexed sender, uint amount0, uint amount1);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out
    );
    event CollectFees(uint amount0, uint amount1);

    error Locked();
    error IdenticalTokens();
    error InsufficientLiquidity();
    error InsufficientInputAmount();
    error InsufficientOutputAmount();
    error TransferFailed();
    error Expired();
    error SlippageExceeded();
    error Overflow();
    error InsufficientAllowance();

    constructor(
        address _token0,
        address _token1,
        address _treasury,
        string memory name,
        string memory symbol
    ) LPToken(name, symbol, address(this)) {
        if (_token0 == _token1) revert IdenticalTokens();
        factory = msg.sender;
        token0 = _token0;
        token1 = _token1;
        treasury = _treasury;
    }

    function getReserves()
        public
        view
        returns (uint112 _reserve0, uint112 _reserve1)
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }

    function _update(uint balance0, uint balance1) private returns (bool) {
        if (balance0 > type(uint112).max || balance1 > type(uint112).max)
            revert Overflow();
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        return true;
    }

    function addLiquidity(
        uint amount0Desired,
        uint amount1Desired
    ) external nonReentrant lock returns (uint liquidity) {
        IERC20(token0).transferFrom(msg.sender, address(this), amount0Desired);
        IERC20(token1).transferFrom(msg.sender, address(this), amount1Desired);

        (uint112 _reserve0, uint112 _reserve1) = getReserves();
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0 - _reserve0;
        uint amount1 = balance1 - _reserve1;

        uint totalSupply = lpToken.totalSupply();
        if (totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1);
        } else {
            liquidity = Math.min(
                (amount0 * totalSupply) / _reserve0,
                (amount1 * totalSupply) / _reserve1
            );
        }
        if (liquidity == 0) revert InsufficientLiquidity();

        lpToken.mintLP(msg.sender, liquidity);
        _approve(msg.sender, address(this), liquidity);

        _update(balance0, balance1);
        emit AddLiquidity(msg.sender, amount0, amount1);
    }

    function removeLiquidity(uint lpAmount) external nonReentrant lock {
        if (lpAmount == 0) revert InsufficientLiquidity();

        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint totalSupply = lpToken.totalSupply();

        uint amount0 = (lpAmount * balance0) / totalSupply;
        uint amount1 = (lpAmount * balance1) / totalSupply;

        uint fees0 = (lpAmount * lpFeeAccumulator0) / totalSupply;
        uint fees1 = (lpAmount * lpFeeAccumulator1) / totalSupply;

        amount0 += fees0;
        amount1 += fees1;

        if (amount0 == 0 && amount1 == 0) revert InsufficientLiquidity();

        lpFeeAccumulator0 -= fees0;
        lpFeeAccumulator1 -= fees1;

        lpToken.burnLP(msg.sender, lpAmount);
        IERC20(token0).transfer(msg.sender, amount0);
        IERC20(token1).transfer(msg.sender, amount1);

        _update(balance0 - amount0, balance1 - amount1);
        emit RemoveLiquidity(msg.sender, amount0, amount1);
    }

    function checkAllowance(
        address user,
        uint amount0,
        uint amount1
    ) public view returns (bool) {
        uint allowance0 = IERC20(token0).allowance(user, address(this));
        uint allowance1 = IERC20(token1).allowance(user, address(this));
        return allowance0 >= amount0 && allowance1 >= amount1;
    }

    function swap(uint amount0Out, uint amount1Out) external nonReentrant lock {
        if (amount0Out == 0 || amount1Out == 0)
            revert InsufficientOutputAmount();

        (uint112 _reserve0, uint112 _reserve1) = getReserves();
        if (amount0Out > _reserve0 || amount1Out > _reserve1)
            revert InsufficientLiquidity();

        uint balance0;
        uint balance1;

        // Transfer tokens to msg.sender
        if (amount0Out > 0) IERC20(token0).transfer(msg.sender, amount0Out);
        if (amount1Out > 0) IERC20(token1).transfer(msg.sender, amount1Out);

        // Get the current balances after transfers
        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));

        // Calculate the input amounts
        uint amount0In = balance0 > _reserve0 - amount0Out
            ? balance0 - (_reserve0 - amount0Out)
            : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out
            ? balance1 - (_reserve1 - amount1Out)
            : 0;

        // Ensure input amounts are provided
        if (amount0In == 0 && amount1In == 0) revert InsufficientInputAmount();

        if (amount0In > 0) {
            uint lpFeeAmount0 = (amount0In * (SWAP_FEE / 2)) / 100;
            uint treasuryFeeAmount0 = (amount0In * (SWAP_FEE / 2)) / 100;
            lpFeeAccumulator0 += lpFeeAmount0;
            IERC20(token0).transfer(treasury, treasuryFeeAmount0);
        }

        if (amount1In > 0) {
            uint lpFeeAmount1 = (amount1In * (SWAP_FEE / 2)) / 100;
            uint treasuryFeeAmount1 = (amount1In * (SWAP_FEE / 2)) / 100;
            lpFeeAccumulator1 += lpFeeAmount1;
            IERC20(token1).transfer(treasury, treasuryFeeAmount1);
        }

        // Transfer input tokens from user to pool
        if (amount0In > 0)
            IERC20(token0).transferFrom(msg.sender, address(this), amount0In);
        if (amount1In > 0)
            IERC20(token1).transferFrom(msg.sender, address(this), amount1In);

        _update(balance0, balance1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out);
    }
}
