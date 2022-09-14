// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IAMM.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ProductAMM is IAMM {
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

    modifier isValidAmount(uint _amount) {
        if (_amount == 0) revert InvalidAmountError(_amount);
        _;
    }

    modifier isValidInject(uint _v1, uint _v2) {
        if (reserveA > 0 || reserveB > 0) {
            require(reserveA * _v2 == reserveB * _v1, "add liquidity failed");
        }
        _;
    }

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function swap(address _addr, uint _amount) 
        external 
        isValidToken(_addr)
        isValidAmount(_amount)
        returns (uint) 
    {
        address self = address(this);
        bool isA = address(tokenA) == _addr;

        (IERC20 tokenIn, IERC20 tokenOut, uint resIn, uint  resOut) = isA
            ? (tokenA, tokenB, reserveA, reserveB)
            : (tokenB, tokenA, reserveB, reserveA);

        tokenIn.transferFrom(msg.sender, self, _amount);
        uint amountMinusFees = (_amount * 997) / 1000;
        uint amountOut = resOut * amountMinusFees / (resIn + amountMinusFees);
        tokenOut.transfer(msg.sender, amountOut);

        _update(tokenA.balanceOf(self), tokenB.balanceOf(self));

        emit CallSawpEvent(msg.sender, address(tokenIn), _amount, address(tokenOut), amountOut);
        return amountOut;
    }

    function injectLiquidity(uint _v1, uint _v2) 
        external 
        isValidInject(_v1, _v2)
        returns (uint shares) 
    {
        address self = address(this);
        tokenA.transferFrom(msg.sender, self, _v1);
        tokenB.transferFrom(msg.sender, self, _v2);

        if (totalSupply == 0) {
            shares = _sqrt(_v1 * _v2);
        }
        else{
            shares = _min(
                (_v1 * totalSupply) / reserveA,
                (_v2 * totalSupply) / reserveB
            );
        }

        _mint(msg.sender, shares);
        _update(tokenA.balanceOf(self), tokenB.balanceOf(self));

        emit InjectLiquidityEvent(msg.sender, _v1, _v2, shares);
    }

    function removeLiquidity(uint _shares) external returns (uint v1, uint v2) {
        address self = address(this);

        uint balA = tokenA.balanceOf(self);
        uint balB = tokenB.balanceOf(self);

        v1 = (_shares * balA) / totalSupply;
        v2 = (_shares * balB) / totalSupply;

        require(v1 > 0 && v2 > 0, "remove liquidity failed.");

        _burn(msg.sender, _shares);
        _update(balA - v1, balB - v2);

        tokenA.transfer(msg.sender, v1);
        tokenB.transfer(msg.sender, v2);

        emit RemoveLiquidityEvent(msg.sender, _shares, v1, v2);
    }

    function _mint(address _to, uint _amount) private {
        balanceOf[_to] += _amount;
        totalSupply += _amount;
    }

    function _burn(address _from, uint _amount) private {
        balanceOf[_from] -= _amount;
        totalSupply -= _amount;
    }

    function _update(uint _v1, uint _v2) private {
        reserveA = _v1;
        reserveB = _v2;
    }

    function _sqrt(uint y) private pure returns (uint z) {
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

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }
}