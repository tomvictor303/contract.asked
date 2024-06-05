// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./BasePlatform.sol";

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