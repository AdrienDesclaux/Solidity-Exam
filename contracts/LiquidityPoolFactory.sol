// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
import "./LiquidityPool.sol";

contract LiquidityPoolFactory {
    mapping(address => mapping(address => address)) public liquidityPools;
    address[] public createdPools;

    event LiquidityPoolCreated(
        address poolAddress,
        address token0,
        address token1
    );

    error InvalidTokenAddress(address token0, address token1);
    error TokensMustBeDifferent(address token0, address token1);

    function createLiquidityPool(
        address _token0,
        address _token1,
        uint8 _swapFee
    ) public returns (address) {
        require(_token0 != _token1, TokensMustBeDifferent(_token0, _token1));
        require(
            _token0 != address(0) && _token1 != address(0),
            InvalidTokenAddress(_token0, _token1)
        );

        LiquidityPool newPool = new LiquidityPool(_token0, _token1, _swapFee);

        liquidityPools[address(_token0)][address(_token1)] = address(newPool);
        liquidityPools[address(_token1)][address(_token0)] = address(newPool);

        createdPools.push(address(newPool));
        emit LiquidityPoolCreated(address(newPool), _token0, _token1);
        return address(newPool);
    }
}
