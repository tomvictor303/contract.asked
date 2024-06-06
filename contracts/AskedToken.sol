// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AskedToken is ERC20 {
    constructor(uint256 initialSupplyByIntegerUnit) ERC20("Asked", "ASK") {
        _mint(msg.sender, initialSupplyByIntegerUnit * 10 ** 18);
    }
}
