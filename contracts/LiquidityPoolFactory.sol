// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
import "./LiquidityPool.sol";

contract LiquidityPoolFactory {
    mapping(address => mapping(address => address)) public liquidityPools;
    address[] public createdPools;
    address public treasury;

    event LiquidityPoolCreated(
        address indexed poolAddress,
        address indexed token0,
        address indexed token1
    );

    error InvalidTokenAddress(address token0, address token1);
    error TokensMustBeDifferent(address token0, address token1);
    error PoolAlreadyExists();

    function createLiquidityPool(
        address _token0,
        address _token1
    ) public returns (address) {
        if (_token0 == _token1) revert TokensMustBeDifferent(_token0, _token1);
        if (_token0 == address(0) || _token1 == address(0))
            revert InvalidTokenAddress(_token0, _token1);
        if (liquidityPools[_token0][_token1] != address(0))
            revert PoolAlreadyExists();

        // Sort tokens to ensure consistent pool addresses
        (address token0, address token1) = _token0 < _token1
            ? (_token0, _token1)
            : (_token1, _token0);

        LiquidityPool newPool = new LiquidityPool(
            token0,
            token1,
            treasury,
            "LP",
            "LP"
        );

        address poolAddress = address(newPool);
        liquidityPools[token0][token1] = poolAddress;
        liquidityPools[token1][token0] = poolAddress;
        createdPools.push(poolAddress);

        emit LiquidityPoolCreated(poolAddress, token0, token1);
        return poolAddress;
    }

    function getPool(
        address tokenA,
        address tokenB
    ) external view returns (address) {
        return liquidityPools[tokenA][tokenB];
    }

    function getAllPools() external view returns (address[] memory) {
        return createdPools;
    }

    function getPoolsCount() external view returns (uint) {
        return createdPools.length;
    }
}
