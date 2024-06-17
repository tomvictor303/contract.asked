// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FreelancePlatform is Ownable {
    // Define job statuses
    enum JobStatus { None, Offer, Refunded, Completed }

    // Define the Job struct
    struct Job {
        address client;
        address freelancer;
        uint256 budget;
        uint256 createdAt;
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
    event JobCreated(uint256 jobId, address client, address freelancer, uint256 budget, uint256 createdAt);
    event JobUpdated(uint256 jobId, JobStatus status);
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
        require(jobs[jobId].client == address(0), "Job ID is already used"); // Check if the jobId is already used
        require(msg.sender != freelancer, "Client and freelancer cannot be same"); // Check if the jobId is already used
        // Transfer ASK tokens from client to contract
        askToken.transferFrom(msg.sender, address(this), budget);

        uint256 currentTime = block.timestamp;
        jobs[jobId] = Job({
            client: msg.sender,
            freelancer: freelancer,
            budget: budget,
            createdAt: currentTime,
            status: JobStatus.Offer
        });

        // Push job ID to client's list of jobs
        jobsFromClient[msg.sender].push(jobId);
        emit JobCreated(jobId, msg.sender, freelancer, budget, currentTime);
    }

    // Update job status and transfer ASK tokens to freelancer if job is completed
    function completeJob(uint256 jobId) public {
        Job storage job = jobs[jobId];
        require(job.status != JobStatus.Refunded, "Job is already refunded");
        require(job.status != JobStatus.Completed, "Job is already completed");
        require(job.status == JobStatus.Offer, "This job is already completed or refunded");
        require(msg.sender == job.client || msg.sender == job.freelancer, "Caller is not authorized. Only freelancer or client can complete.");

        // Transfer ASK tokens to freelancer
        require(askToken.transfer(job.freelancer, job.budget), "Token transfer to freelancer failed");
        // Mark job as complete after transfer
        job.status = JobStatus.Completed;
        emit JobUpdated(jobId, JobStatus.Completed);
    }

    // Mark job as refunded and return ASK tokens to client
    function refundJob(uint256 jobId) public {
        Job storage job = jobs[jobId];
        require(msg.sender == job.client, "Caller is not authorized. Only client can refund.");
        require(job.status != JobStatus.Refunded, "Job is already refunded");
        require(job.status != JobStatus.Completed, "Job is already completed");
        require(job.status == JobStatus.Offer, "This job is already completed or refunded");
        // Transfer ASK tokens back to client
        require(askToken.transfer(job.client, job.budget), "Token refund failed");
        // Mark job as refunded
        job.status = JobStatus.Refunded;
        emit JobUpdated(jobId, JobStatus.Refunded);
    }

    // Get job details
    function getJob(uint256 jobId) public view returns (Job memory) {
        return jobs[jobId];
    }

    // Get job details
    function getJobsFromClient(address client) public view returns (uint256[] memory) {
        return jobsFromClient[client];
    }
}
