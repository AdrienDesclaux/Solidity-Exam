// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CustomERC20 is ERC20 {
    error InvalidSupply();
    error InvalidNameOrSymbol();

    event TokenCreated(string name, string symbol, uint256 initialSupply);

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        if (initialSupply == 0) revert InvalidSupply();
        if (bytes(name).length == 0 || bytes(symbol).length == 0)
            revert InvalidNameOrSymbol();

        _mint(msg.sender, initialSupply);
        emit TokenCreated(name, symbol, initialSupply);
    }

    function mint(address to, uint256 amount) internal {
        _mint(to, amount);
    }
}
