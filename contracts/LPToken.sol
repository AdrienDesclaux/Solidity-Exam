// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LPToken is ERC20 {
    address public immutable liquidityPool;

    error Unauthorized();
    error InvalidAddress();

    event LPTokenMinted(address indexed to, uint256 amount);
    event LPTokenBurned(address indexed from, uint256 amount);

    modifier onlyLiquidityPool() {
        if (msg.sender != liquidityPool) revert Unauthorized();
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address _liquidityPool
    ) ERC20(name, symbol) {
        require(_liquidityPool != address(0), InvalidAddress());
        liquidityPool = _liquidityPool;
    }

    function mintLP(address to, uint amount) external onlyLiquidityPool {
        _mint(to, amount);
        emit LPTokenMinted(to, amount);
    }

    function burnLP(address from, uint amount) external onlyLiquidityPool {
        _burn(from, amount);
        emit LPTokenBurned(from, amount);
    }
}
