// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BasePlatform {
    address public owner;
    uint256 private rate;
    uint256 private expireDuration;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event RateUpdated(uint256 oldRate, uint256 newRate);
    event ExpireDurationUpdated(uint256 oldDuration, uint256 newDuration);

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    function changeOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

    function isOwner(address _address) public view returns (bool) {
        return _address == owner;
    }

}