// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FreelancePlatform {
    address public owner;
    uint256 private rate;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event RateUpdated(uint256 oldRate, uint256 newRate);

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
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }

    function setRate(uint256 newRate) public onlyOwner {
        rate = newRate;
        emit RateUpdated(rate, newRate);
    }

    function getRate() public view returns (uint256) {
        return rate;
    }

    function isOwner(address _address) public view returns (bool) {
        return _address == owner;
    }
}