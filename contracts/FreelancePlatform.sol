// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FreelancePlatform is Ownable {
    // Define job statuses
    enum JobStatus { None, Offer, Canceled, Completed }

    // Define the Job struct
    struct Job {
        address client;
        address freelancer;
        uint256 budget;
        uint256 createdAt;
        bool isRefunded;
        JobStatus status;
    }

    // Rate and expire duration settings
    uint256 private rate;
    uint256 private expireDuration;

    // Mapping from job ID to Job struct
    mapping(uint256 => Job) public jobs;

    // Mapping from client address to list of job IDs
    mapping(address => uint256[]) public jobsFromClient;

    // ASK token contract
    IERC20 public askToken;

    // Events for job management
    event JobCreated(uint256 jobId, address client, uint256 budget, uint256 createdAt);
    event JobUpdated(uint256 jobId, JobStatus status);
    event JobRefunded(uint256 jobId, bool isRefunded);
    event RateUpdated(uint256 oldRate, uint256 newRate);
    event ExpireDurationUpdated(uint256 oldDuration, uint256 newDuration);

    // Constructor to initialize the ASK token address and Ownable
    constructor(address _askTokenAddress) Ownable(msg.sender) {
        askToken = IERC20(_askTokenAddress);
        rate = 0;
        expireDuration = 24 * 3600;
    }

    // Set new rate
    function setRate(uint256 newRate) public onlyOwner {
        uint256 oldRate = rate;
        rate = newRate;
        emit RateUpdated(oldRate, newRate);
    }

    // Set new expire duration
    function setExpireDuration(uint256 newDuration) public onlyOwner {
        uint256 oldDuration = expireDuration;
        expireDuration = newDuration;
        emit ExpireDurationUpdated(oldDuration, newDuration);
    }

    // Get current rate
    function getRate() public view returns (uint256) {
        return rate;
    }

    // Get current expire duration
    function getExpireDuration() public view returns (uint256) {
        return expireDuration;
    }
    
    // Create a new job and transfer ASK tokens from client to contract
    function createJob(uint256 jobId, address freelancer, uint256 budget) public {
        require(jobs[jobId].client == address(0), "Job ID already used"); // Check if the jobId is already used
        // Transfer ASK tokens from client to contract
        require(askToken.transferFrom(msg.sender, address(this), budget), "Token transfer failed");

        uint256 currentTime = block.timestamp;
        jobs[jobId] = Job({
            client: msg.sender,
            freelancer: freelancer,
            budget: budget,
            createdAt: currentTime,
            isRefunded: false,
            status: JobStatus.Offer
        });

        // Push job ID to client's list of jobs
        jobsFromClient[msg.sender].push(jobId);
        emit JobCreated(jobId, msg.sender, budget, currentTime);
    }

    // Update job status and transfer ASK tokens to freelancer if job is completed
    function completeJob(uint256 jobId) public {
        Job storage job = jobs[jobId];
        require(msg.sender == job.client || msg.sender == job.freelancer, "Caller is not authorized");
        job.status = JobStatus.Completed;

        // Transfer ASK tokens to freelancer if job is completed
        require(askToken.transfer(job.freelancer, job.budget), "Token transfer to freelancer failed");
        emit JobUpdated(jobId, JobStatus.Completed);
    }

    // Mark job as refunded and return ASK tokens to client
    function refundJob(uint256 jobId) public onlyOwner {
        Job storage job = jobs[jobId];
        require(msg.sender == job.client, "Caller is not authorized. Only client can refund.");
        require(!job.isRefunded, "Job is already refunded");
        job.isRefunded = true;
        job.status = JobStatus.Canceled;

        // Transfer ASK tokens back to client
        require(askToken.transfer(job.client, job.budget), "Token refund failed");
        emit JobRefunded(jobId, true);
    }

    // Get job details
    function getJob(uint256 jobId) public view returns (Job memory) {
        return jobs[jobId];
    }
}
