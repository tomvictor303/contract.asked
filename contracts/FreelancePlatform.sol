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
    uint256 public nextJobId;

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
        
        // Transfer ASK tokens from client to contract
        require(askToken.transferFrom(msg.sender, address(this), budget), "Token transfer failed");

        nextJobId++;
    }

    // Update job status and transfer ASK tokens to freelancer if job is completed
    function updateJobStatus(uint256 jobId, JobStatus status) public {
        Job storage job = jobs[jobId];
        require(msg.sender == job.client || msg.sender == job.freelancer, "Caller is not authorized");
        job.status = status;
        emit JobUpdated(jobId, status);

        // Transfer ASK tokens to freelancer if job is completed
        if (status == JobStatus.Completed) {
            require(askToken.transfer(job.freelancer, job.budget), "Token transfer to freelancer failed");
        }
    }

    // Mark job as refunded and return ASK tokens to client
    function refundJob(uint256 jobId) public onlyOwner {
        Job storage job = jobs[jobId];
        require(!job.isRefunded, "Job is already refunded");
        job.isRefunded = true;
        emit JobRefunded(jobId, true);

        // Transfer ASK tokens back to client
        require(askToken.transfer(job.client, job.budget), "Token refund failed");
    }

    // Get job details
    function getJob(uint256 jobId) public view returns (Job memory) {
        return jobs[jobId];
    }
}
