// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20("TestToken", "TK") {}

    function mint(uint _value) external {
        _mint(msg.sender, _value);
    }

    function burn(uint _value) external {
        _burn(msg.sender, _value);
    }
}