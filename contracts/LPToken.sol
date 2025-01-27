// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LPtoken is ERC20 {

    address public liquidityPool;

    error InvalidLiquidityPool(address liquidityPool);

    modifier onlyLiquidityPool() {
        require(msg.sender == liquidityPool, InvalidLiquidityPool(liquidityPool));
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address _liquidityPool
    ) ERC20(name, symbol) {
        liquidityPool = _liquidityPool;
    }

    function mintLP(address to, uint amount) internal onlyLiquidityPool() {
        _mint(to, amount);
    }

    function burnLP(address to, uint amount) internal onlyLiquidityPool() {
        _burn(to, amount);
    }
}
