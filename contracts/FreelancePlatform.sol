// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20} from '@openzeppelin/contracts/interfaces/IERC20.sol';
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract FreelancePlatform is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    // Define job statuses
    enum PayStatus { None, Offer, Refunded, Completed }

    // Define the Job struct
    struct Job {
        address client;
        address freelancer;
        uint256 budget;
        uint256 createdAt;
        PayStatus payStatus;
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
    event JobPayStatusUpdated(uint256 jobId, PayStatus payStatus);
    event RateUpdated(uint256 oldRate, uint256 newRate);
    event ExpireDurationUpdated(uint256 oldDuration, uint256 newDuration);

    // Initializer function (replaces constructor for upgradeable contracts)
    function initialize(address _askTokenAddress) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        askToken = IERC20(_askTokenAddress);
        rate = 0;
        expireDuration = 24 * 3600;
    }

    // Function required by UUPSUpgradeable
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

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
        require(msg.sender != freelancer, "Payment sender and receiver cannot be same"); // Check if the jobId is already used
        require(
            askToken.allowance(msg.sender, address(this)) >= budget,
            "Your allowance of token-transfer is not enough"
        );
        // Transfer ASK tokens from client to contract
        askToken.transferFrom(msg.sender, address(this), budget);

        uint256 currentTime = block.timestamp;
        jobs[jobId] = Job({
            client: msg.sender,
            freelancer: freelancer,
            budget: budget,
            createdAt: currentTime,
            payStatus: PayStatus.Offer
        });

        // Push job ID to client's list of jobs
        jobsFromClient[msg.sender].push(jobId);
        emit JobCreated(jobId, msg.sender, freelancer, budget, currentTime);
    }

    // Update job payStatus and transfer ASK tokens to freelancer if job is completed
    function completeJob(uint256 jobId) public {
        Job storage job = jobs[jobId];
        require(job.client != address(0), "This Job ID is not registered on blockchain");
        require(job.payStatus != PayStatus.Refunded, "This payment is already refunded");
        require(job.payStatus != PayStatus.Completed, "This payment is already completed");
        require(job.payStatus == PayStatus.Offer, "This payment is already completed or refunded");
        require(msg.sender == job.client || msg.sender == job.freelancer, "Caller is not authorized. Only payment sender or receiver can complete it.");
        require(block.timestamp <= job.createdAt + expireDuration, "Job completion period has already expired");

        // Transfer ASK tokens to freelancer
        require(askToken.transfer(job.freelancer, job.budget), "Token transfer to receiver failed");
        // Mark job as complete after transfer
        job.payStatus = PayStatus.Completed;
        emit JobPayStatusUpdated(jobId, PayStatus.Completed);
    }

    // Mark job as refunded and return ASK tokens to client
    function refundJob(uint256 jobId) public {
        Job storage job = jobs[jobId];
        require(job.client != address(0), "This Job ID is not registered on blockchain");
        require(job.payStatus != PayStatus.Refunded, "This payment is already refunded");
        require(job.payStatus != PayStatus.Completed, "This payment is already completed");
        require(job.payStatus == PayStatus.Offer, "This payment is already completed or refunded");
        require(msg.sender == job.client, "Caller is not authorized. Only payment sender can refund.");
        // Transfer ASK tokens back to client
        require(askToken.transfer(job.client, job.budget), "Token refund failed");
        // Mark job as refunded
        job.payStatus = PayStatus.Refunded;
        emit JobPayStatusUpdated(jobId, PayStatus.Refunded);
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
