// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract ExomemGovernance is Ownable, ReentrancyGuard, Pausable {
    IERC20 public immutable exomemToken;
    
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        string ipfsHash; // For detailed proposal information
        uint256 forVotes;
        uint256 againstVotes;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        bool canceled;
    }
    
    // Mapping from proposal ID to Proposal
    mapping(uint256 => Proposal) public proposals;
    
    // Mapping from proposal ID to voter address to whether they've voted
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    
    // Minimum token balance required to create a proposal
    uint256 public proposalThreshold = 1000000 * 10**18; // 1 million EX0
    
    // Minimum token balance required to vote
    uint256 public voteThreshold = 10000 * 10**18; // 10,000 EX0
    
    // Voting period in seconds (default: 3 days)
    uint256 public votingPeriod = 3 days;
    
    // Timelock period before execution (default: 1 day)
    uint256 public executionDelay = 1 days;
    
    // Total number of proposals
    uint256 public proposalCount;
    
    // Events
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);
    event ThresholdUpdated(string thresholdType, uint256 newValue);
    event VotingPeriodUpdated(uint256 newPeriod);
    event ExecutionDelayUpdated(uint256 newDelay);
    
    constructor(address _tokenAddress) Ownable(msg.sender) {
        exomemToken = IERC20(_tokenAddress);
    }
    
    // Create a new governance proposal
    function createProposal(string memory description, string memory ipfsHash) 
        external 
        whenNotPaused 
    {
        require(exomemToken.balanceOf(msg.sender) >= proposalThreshold, "EX0 balance below proposal threshold");
        
        uint256 proposalId = proposalCount++;
        
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: description,
            ipfsHash: ipfsHash,
            forVotes: 0,
            againstVotes: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod,
            executed: false,
            canceled: false
        });
        
        emit ProposalCreated(proposalId, msg.sender, description);
    }
    
    // Cast vote on a proposal
    function castVote(uint256 proposalId, bool support) 
        external 
        whenNotPaused 
    {
        require(proposalId < proposalCount, "Invalid proposal ID");
        require(exomemToken.balanceOf(msg.sender) >= voteThreshold, "EX0 balance below vote threshold");
        
        Proposal storage proposal = proposals[proposalId];
        
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.canceled, "Proposal has been canceled");
        require(block.timestamp >= proposal.startTime, "Voting has not started");
        require(block.timestamp <= proposal.endTime, "Voting has ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted");
        
        hasVoted[proposalId][msg.sender] = true;
        
        uint256 votes = exomemToken.balanceOf(msg.sender);
        
        if (support) {
            proposal.forVotes += votes;
        } else {
            proposal.againstVotes += votes;
        }
        
        emit VoteCast(proposalId, msg.sender, support, votes);
    }
    
    // Execute a proposal after voting has ended and timelock has passed
    function executeProposal(uint256 proposalId) 
        external 
        onlyOwner 
        whenNotPaused 
        nonReentrant 
    {
        require(proposalId < proposalCount, "Invalid proposal ID");
        
        Proposal storage proposal = proposals[proposalId];
        
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.canceled, "Proposal has been canceled");
        require(block.timestamp > proposal.endTime, "Voting has not ended");
        require(block.timestamp >= proposal.endTime + executionDelay, "Execution delay not met");
        require(proposal.forVotes > proposal.againstVotes, "Proposal did not pass");
        
        proposal.executed = true;
        
        emit ProposalExecuted(proposalId);
        
        // Implementation of proposal execution would go here
        // This could involve calling other contracts or functions
    }
    
    // Cancel a proposal (only by proposer or owner)
    function cancelProposal(uint256 proposalId) 
        external 
        whenNotPaused 
    {
        require(proposalId < proposalCount, "Invalid proposal ID");
        
        Proposal storage proposal = proposals[proposalId];
        
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.canceled, "Proposal already canceled");
        require(msg.sender == proposal.proposer || msg.sender == owner(), "Not authorized to cancel");
        
        proposal.canceled = true;
        
        emit ProposalCanceled(proposalId);
    }
    
    // Update the proposal threshold
    function setProposalThreshold(uint256 newThreshold) external onlyOwner {
        proposalThreshold = newThreshold;
        emit ThresholdUpdated("Proposal", newThreshold);
    }
    
    // Update the vote threshold
    function setVoteThreshold(uint256 newThreshold) external onlyOwner {
        voteThreshold = newThreshold;
        emit ThresholdUpdated("Vote", newThreshold);
    }
    
    // Update the voting period
    function setVotingPeriod(uint256 newPeriod) external onlyOwner {
        require(newPeriod >= 1 days, "Voting period too short");
        votingPeriod = newPeriod;
        emit VotingPeriodUpdated(newPeriod);
    }
    
    // Update the execution delay
    function setExecutionDelay(uint256 newDelay) external onlyOwner {
        require(newDelay >= 1 hours, "Execution delay too short");
        executionDelay = newDelay;
        emit ExecutionDelayUpdated(newDelay);
    }
    
    // Pause governance in emergency
    function pause() external onlyOwner {
        _pause();
    }
    
    // Unpause governance
    function unpause() external onlyOwner {
        _unpause();
    }
}