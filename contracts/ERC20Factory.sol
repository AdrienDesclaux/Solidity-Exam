// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./CustomERC20.sol";

contract ERC20Factory {
    error EmptyName();
    error EmptySymbol();
    error InvalidSupply();

    event NewToken(
        address indexed _token,
        address indexed _owner,
        string _name,
        string _symbol,
        uint _supply
    );

    // Mapping of token name to token address
    mapping(string => address) public tokens;

    // Mapping of token symbol to token address
    mapping(string => address) public symbols;

    // Array to store token addresses
    address[] private tokenList;

    function createToken(
        string memory _name,
        string memory _symbol,
        uint _supply
    ) public returns (address) {
        if (compareStrings(_name, "")) revert EmptyName();
        if (compareStrings(_symbol, "")) revert EmptySymbol();
        if (_supply == 0) revert InvalidSupply();

        CustomERC20 newToken = new CustomERC20(_name, _symbol, _supply);
        address tokenAddress = address(newToken);

        tokens[_name] = tokenAddress;
        symbols[_symbol] = tokenAddress;

        // Add the new token address to the list
        tokenList.push(tokenAddress);

        emit NewToken(tokenAddress, msg.sender, _name, _symbol, _supply);

        return tokenAddress;
    }

    function getTokenAddress(string memory name) public view returns (address) {
        return tokens[name];
    }

    function getAllTokens() public view returns (address[] memory) {
        return tokenList;
    }

    function compareStrings(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}
