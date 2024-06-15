// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BasePlatform is Ownable {
    uint256 private rate; // integer rate
    uint256 private expireDuration; // seconds

    event RateUpdated(uint256 oldRate, uint256 newRate);
    event ExpireDurationUpdated(uint256 oldDuration, uint256 newDuration);

    constructor() Ownable(msg.sender) {
        rate = 0;
        expireDuration = 24 * 3600;
    }

    function setRate(uint256 newRate) public onlyOwner {
        uint256 oldRate = rate;
        rate = newRate;
        emit RateUpdated(oldRate, newRate);
    }

    function setExpireDuration(uint256 newDuration) public onlyOwner {
        uint256 oldDuration = expireDuration;
        expireDuration = newDuration;
        emit ExpireDurationUpdated(oldDuration, newDuration);
    }

    function getRate() public view returns (uint256) {
        return rate;
    }

    function getExpireDuration() public view returns (uint256) {
        return expireDuration;
    }
}
