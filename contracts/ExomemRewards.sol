// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract ExomemRewards is Ownable, ReentrancyGuard, Pausable {
    IERC20 public immutable exomemToken;
    
    struct Contest {
        string name;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 rewardPool;
        bool active;
    }
    
    struct Submission {
        address creator;
        string contentURI;
        uint256 votes;
        bool rewarded;
    }
    
    // Mapping of contest ID to Contest
    mapping(uint256 => Contest) public contests;
    
    // Mapping of contest ID to submission ID to Submission
    mapping(uint256 => mapping(uint256 => Submission)) public submissions;
    
    // Number of contests and submissions
    uint256 public contestCount;
    mapping(uint256 => uint256) public submissionCounts;
    
    // Mapping to track voter participation
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    
    // Events
    event ContestCreated(uint256 indexed contestId, string name, uint256 startTime, uint256 endTime, uint256 rewardPool);
    event SubmissionAdded(uint256 indexed contestId, uint256 submissionId, address indexed creator, string contentURI);
    event VoteCast(uint256 indexed contestId, uint256 submissionId, address indexed voter);
    event RewardDistributed(uint256 indexed contestId, uint256 submissionId, address indexed creator, uint256 amount);
    event AirdropExecuted(address[] recipients, uint256[] amounts);
    event EmergencyWithdrawal(address indexed owner, uint256 amount);
    
    constructor(address _tokenAddress) Ownable(msg.sender) {
        exomemToken = IERC20(_tokenAddress);
    }
    
    // Create a new meme contest
    function createContest(
        string memory name,
        string memory description,
        uint256 startTime,
        uint256 endTime,
        uint256 rewardPool
    ) external onlyOwner whenNotPaused {
        require(startTime < endTime, "End time must be after start time");
        require(startTime > block.timestamp, "Start time must be in the future");
        require(rewardPool > 0, "Reward pool must be positive");
        require(exomemToken.balanceOf(address(this)) >= rewardPool, "Insufficient token balance for reward pool");
        
        uint256 contestId = contestCount;
        contests[contestId] = Contest({
            name: name,
            description: description,
            startTime: startTime,
            endTime: endTime,
            rewardPool: rewardPool,
            active: true
        });
        
        contestCount++;
        
        emit ContestCreated(contestId, name, startTime, endTime, rewardPool);
    }
    
    // Submit a meme to a contest
    function submitContent(uint256 contestId, string memory contentURI) external whenNotPaused {
        Contest memory contest = contests[contestId];
        require(contest.active, "Contest is not active");
        require(block.timestamp >= contest.startTime, "Contest has not started");
        require(block.timestamp <= contest.endTime, "Contest has ended");
        
        uint256 submissionId = submissionCounts[contestId];
        submissions[contestId][submissionId] = Submission({
            creator: msg.sender,
            contentURI: contentURI,
            votes: 0,
            rewarded: false
        });
        
        submissionCounts[contestId]++;
        
        emit SubmissionAdded(contestId, submissionId, msg.sender, contentURI);
    }
    
    // Vote for a submission
    function voteForSubmission(uint256 contestId, uint256 submissionId) external whenNotPaused {
        Contest memory contest = contests[contestId];
        require(contest.active, "Contest is not active");
        require(block.timestamp >= contest.startTime, "Contest has not started");
        require(block.timestamp <= contest.endTime, "Contest has ended");
        require(submissionId < submissionCounts[contestId], "Invalid submission ID");
        require(!hasVoted[contestId][msg.sender], "Already voted in this contest");
        
        hasVoted[contestId][msg.sender] = true;
        submissions[contestId][submissionId].votes++;
        
        emit VoteCast(contestId, submissionId, msg.sender);
    }
    
    // Distribute rewards for a contest
    function distributeRewards(uint256 contestId, uint256[] memory winningSubmissionIds, uint256[] memory rewardAmounts) 
        external 
        onlyOwner 
        whenNotPaused 
        nonReentrant 
    {
        Contest storage contest = contests[contestId];
        require(contest.active, "Contest is not active");
        require(block.timestamp > contest.endTime, "Contest has not ended");
        require(winningSubmissionIds.length == rewardAmounts.length, "Arrays must have the same length");
        
        uint256 totalRewards = 0;
        for (uint256 i = 0; i < rewardAmounts.length; i++) {
            totalRewards += rewardAmounts[i];
        }
        require(totalRewards <= contest.rewardPool, "Total rewards exceed the reward pool");
        
        for (uint256 i = 0; i < winningSubmissionIds.length; i++) {
            uint256 submissionId = winningSubmissionIds[i];
            require(submissionId < submissionCounts[contestId], "Invalid submission ID");
            
            Submission storage submission = submissions[contestId][submissionId];
            require(!submission.rewarded, "Submission already rewarded");
            
            submission.rewarded = true;
            require(exomemToken.transfer(submission.creator, rewardAmounts[i]), "Token transfer failed");
            
            emit RewardDistributed(contestId, submissionId, submission.creator, rewardAmounts[i]);
        }
        
        contest.active = false;
    }
    
    // Airdrop tokens to multiple addresses
    function airdropTokens(address[] memory recipients, uint256[] memory amounts) 
        external 
        onlyOwner 
        whenNotPaused 
        nonReentrant 
    {
        require(recipients.length == amounts.length, "Arrays must have the same length");
        require(recipients.length <= 100, "Too many recipients in a single transaction");
        
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        require(exomemToken.balanceOf(address(this)) >= totalAmount, "Insufficient token balance for airdrop");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Cannot airdrop to zero address");
            require(exomemToken.transfer(recipients[i], amounts[i]), "Token transfer failed");
        }
        
        emit AirdropExecuted(recipients, amounts);
    }
    
    // Emergency withdrawal of tokens
    function emergencyWithdraw(uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(amount <= exomemToken.balanceOf(address(this)), "Insufficient balance");
        
        require(exomemToken.transfer(owner(), amount), "Token transfer failed");
        
        emit EmergencyWithdrawal(owner(), amount);
    }
    
    // Pause contract in emergency
    function pause() external onlyOwner {
        _pause();
    }
    
    // Unpause contract
    function unpause() external onlyOwner {
        _unpause();
    }
}