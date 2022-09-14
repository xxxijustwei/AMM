// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IAMM.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SumAMM is IAMM {
    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;

    uint public reserveA;
    uint public reserveB;

    uint public totalSupply;
    mapping(address => uint) public balanceOf;

    modifier isValidToken(address _addr) {
        if (address(tokenA) != _addr || address(tokenB) != _addr) revert InvalidTokenError(_addr);
        _;
    }

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function _mint(address _to, uint _amount) private {
        balanceOf[_to] += _amount;
        totalSupply += _amount;
    }

    function _burn(address _form, uint _amount) private {
        balanceOf[_form] -= _amount;
        totalSupply -= _amount;
    }

    function _update(uint _v1, uint _v2) private {
        reserveA = _v1;
        reserveB = _v2;
    }

    function swap(address _addr, uint _amount) 
        external 
        isValidToken(_addr)
        returns (uint) 
    {
        bool isA = address(tokenA) == _addr;

        (IERC20 tokenIn, IERC20 tokenOut, uint resIn, uint resOut) = isA
            ? (tokenA, tokenB, reserveA, reserveB)
            : (tokenB, tokenA, reserveB, reserveA);

        tokenIn.transferFrom(msg.sender, address(this), _amount);
        uint amountIn = tokenIn.balanceOf(address(this)) - resIn;
        uint amountOut = (amountIn * 997) / 1000;

        (uint v1, uint v2) = isA
            ? (resIn + amountIn, resOut - amountOut)
            : (resOut - amountOut, resIn + amountIn);
        
        _update(v1, v2);
        tokenOut.transfer(msg.sender, amountOut);

        emit CallSawpEvent(msg.sender, address(tokenIn), amountIn, address(tokenOut), amountOut);
        return amountOut;
    }

    function injectLiquidity(uint _v1, uint _v2) external returns (uint shares) {
        address receiver = address(this);
        tokenA.transferFrom(msg.sender, receiver, _v1);
        tokenB.transferFrom(msg.sender, receiver, _v2);

        uint balA = tokenA.balanceOf(receiver);
        uint balB = tokenB.balanceOf(receiver);

        uint d1 = balA - reserveA;
        uint d2 = balB - reserveB;

        if (totalSupply > 0) {
            shares = ((d1 + d2) * totalSupply) / (reserveA + reserveB);
        } else {
            shares = d1 + d2;
        }

        require(shares > 0, "inject liquidity failed.");

        _mint(msg.sender, shares);
        _update(balA, balB);

        emit InjectLiquidityEvent(msg.sender, d1, d2, shares);
    }

    function removeLiquidity(uint _shares) external returns (uint v1, uint v2) {
        address sender = msg.sender;

        v1 = (reserveA * _shares) / totalSupply;
        v2 = (reserveB * _shares) / totalSupply;

        _burn(sender, _shares);
        _update(reserveA - v1, reserveB - v2);

        if (v1 > 0) tokenA.transfer(sender, v1);
        if (v2 > 0) tokenB.transfer(sender, v2);

        emit RemoveLiquidityEvent(sender, _shares, v1, v2);
    }
}