// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FreelancePlatform {
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

    // Define job statuses
    enum JobStatus { None, Offer, Canceled, Completed }

    // Define the Job struct
    struct Job {
        address client;
        address freelancer;
        uint256 budget;
        uint256 createdAt;
        uint256 offeredAt;
        bool isRefunded;
        JobStatus status;
    }

    // Mapping from job ID to Job struct
    mapping(uint256 => Job) public jobs;
    uint256 public nextJobId;

    // Events for job management
    event JobCreated(uint256 jobId, address client, uint256 budget, uint256 createdAt);
    event JobUpdated(uint256 jobId, JobStatus status);
    event JobRefunded(uint256 jobId, bool isRefunded);

    // Create a new job
    function createJob(address freelancer, uint256 budget) public {
        uint256 currentTime = block.timestamp;
        jobs[nextJobId] = Job({
            client: msg.sender,
            freelancer: freelancer,
            budget: budget,
            createdAt: currentTime,
            offeredAt: currentTime,
            isRefunded: false,
            status: JobStatus.Offer
        });
        emit JobCreated(nextJobId, msg.sender, budget, currentTime);
        nextJobId++;
    }

    // Update job status
    function updateJobStatus(uint256 jobId, JobStatus status) public {
        Job storage job = jobs[jobId];
        require(msg.sender == job.client || msg.sender == job.freelancer, "Caller is not authorized");
        job.status = status;
        emit JobUpdated(jobId, status);
    }

    // Mark job as refunded
    function refundJob(uint256 jobId) public onlyOwner {
        Job storage job = jobs[jobId];
        job.isRefunded = true;
        emit JobRefunded(jobId, true);
    }

    // Get job details
    function getJob(uint256 jobId) public view returns (Job memory) {
        return jobs[jobId];
    }
}