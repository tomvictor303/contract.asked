// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BasePlatform.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FreelancePlatform is BasePlatform {
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

    // Mapping from client address to list of job IDs
    mapping(address => uint256[]) public jobsFromClient;

    // ASK token contract
    IERC20 public askToken;

    // Events for job management
    event JobCreated(uint256 jobId, address client, uint256 budget, uint256 createdAt);
    event JobUpdated(uint256 jobId, JobStatus status);
    event JobRefunded(uint256 jobId, bool isRefunded);

    // Constructor to initialize the ASK token address
    constructor(address _askTokenAddress) {
        askToken = IERC20(_askTokenAddress);
    }

    // Create a new job and transfer ASK tokens from client to contract
    function createJob(uint256 jobId, address freelancer, uint256 budget) public {
        uint256 currentTime = block.timestamp;
        jobs[jobId] = Job({
            client: msg.sender,
            freelancer: freelancer,
            budget: budget,
            createdAt: currentTime,
            offeredAt: currentTime,
            isRefunded: false,
            status: JobStatus.Offer
        });
        emit JobCreated(jobId, msg.sender, budget, currentTime);

        // Push job ID to client's list of jobs
        jobsFromClient[msg.sender].push(jobId);
        
        // Transfer ASK tokens from client to contract
        require(askToken.transferFrom(msg.sender, address(this), budget), "Token transfer failed");
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
