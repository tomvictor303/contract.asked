// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FreelancePlatform {
    address public owner;
    
    enum JobStatus { Open, InProgress, Completed }
    
    struct Job {
        uint256 id;
        address client;
        address freelancer;
        uint256 amount;
        JobStatus status;
        string description; // New field for description
    }
    
    uint256 public jobCount;
    mapping(uint256 => Job) public jobs;
    
    event JobPosted(uint256 id, address client, uint256 amount, string description);
    event JobTaken(uint256 id, address freelancer);
    event JobCompleted(uint256 id);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner); // New event

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }
    
    modifier onlyClient(uint256 _jobId) {
        require(jobs[_jobId].client == msg.sender, "Caller is not the client");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function postJob(string memory _description) public payable {
        require(msg.value > 0, "Amount must be greater than zero");
        jobCount++;
        jobs[jobCount] = Job(jobCount, msg.sender, address(0), msg.value, JobStatus.Open, _description);
        emit JobPosted(jobCount, msg.sender, msg.value, _description);
    }

    function takeJob(uint256 _jobId) public {
        Job storage job = jobs[_jobId];
        require(job.status == JobStatus.Open, "Job not open");
        job.freelancer = msg.sender;
        job.status = JobStatus.InProgress;
        emit JobTaken(_jobId, msg.sender);
    }

    function completeJob(uint256 _jobId) public onlyClient(_jobId) {
        Job storage job = jobs[_jobId];
        require(job.status == JobStatus.InProgress, "Job not in progress");
        job.status = JobStatus.Completed;
        payable(job.freelancer).transfer(job.amount);
        emit JobCompleted(_jobId);
    }
    
    function changeOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function isOwner(address _address) public view returns (bool) {
        return _address == owner;
    }
}
