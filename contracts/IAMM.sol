// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IAMM {

    event CallSawpEvent(address indexed sender, address from, uint input, address to, uint output);
    event InjectLiquidityEvent(address indexed sender, uint v1, uint v2, uint shares);
    event RemoveLiquidityEvent(address indexed sender, uint shares, uint v1, uint v2);

    error InvalidTokenError(address addr);
    error InvalidAmountError(uint amount);

    function swap(address _addr, uint _amount) external returns (uint);

    function injectLiquidity(uint _v1, uint _v2) external returns (uint shares);

    function removeLiquidity(uint _shares) external returns (uint v1, uint v2);
}