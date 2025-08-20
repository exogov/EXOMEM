// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract ExomemEcosystemFund is Ownable, ReentrancyGuard, Pausable {
    IERC20 public immutable exomemToken;
    
    struct Grant {
        uint256 id;
        address recipient;
        uint256 amount;
        string description;
        string ipfsHash; // For detailed grant information
        uint256 approvalCount;
        bool executed;
        bool canceled;
        mapping(address => bool) approvals;
    }
    
    struct GrantInfo {
        uint256 id;
        address recipient;
        uint256 amount;
        string description;
        string ipfsHash;
        uint256 approvalCount;
        bool executed;
        bool canceled;
    }
    
    // Mapping from grant ID to Grant
    mapping(uint256 => Grant) private grants;
    
    // Total number of grants
    uint256 public grantCount;
    
    // Approvers who can approve grants
    mapping(address => bool) public approvers;
    address[] public approversList;
    
    // Number of approvals required to execute a grant
    uint256 public requiredApprovals = 2;
    
    // Events
    event GrantProposed(uint256 indexed grantId, address indexed recipient, uint256 amount, string description);
    event GrantApproved(uint256 indexed grantId, address indexed approver);
    event GrantExecuted(uint256 indexed grantId, address indexed recipient, uint256 amount);
    event GrantCanceled(uint256 indexed grantId);
    event ApproverAdded(address indexed approver);
    event ApproverRemoved(address indexed approver);
    event RequiredApprovalsUpdated(uint256 newValue);
    
    constructor(address _tokenAddress) Ownable(msg.sender) {
        exomemToken = IERC20(_tokenAddress);
        
        // Add owner as initial approver
        approvers[owner()] = true;
        approversList.push(owner());
    }
    
    // Propose a new ecosystem grant
    function proposeGrant(
        address recipient, 
        uint256 amount, 
        string memory description, 
        string memory ipfsHash
    ) 
        external 
        onlyOwner 
        whenNotPaused 
    {
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Grant amount must be positive");
        require(amount <= exomemToken.balanceOf(address(this)), "Insufficient funds in contract");
        
        uint256 grantId = grantCount;
        
        Grant storage newGrant = grants[grantId];
        newGrant.id = grantId;
        newGrant.recipient = recipient;
        newGrant.amount = amount;
        newGrant.description = description;
        newGrant.ipfsHash = ipfsHash;
        newGrant.approvalCount = 0;
        newGrant.executed = false;
        newGrant.canceled = false;
        
        grantCount++;
        
        emit GrantProposed(grantId, recipient, amount, description);
    }
    
    // Approve a grant
    function approveGrant(uint256 grantId) 
        external 
        whenNotPaused 
    {
        require(approvers[msg.sender], "Not an approver");
        require(grantId < grantCount, "Invalid grant ID");
        
        Grant storage grant = grants[grantId];
        
        require(!grant.executed, "Grant already executed");
        require(!grant.canceled, "Grant has been canceled");
        require(!grant.approvals[msg.sender], "Already approved this grant");
        
        grant.approvals[msg.sender] = true;
        grant.approvalCount++;
        
        emit GrantApproved(grantId, msg.sender);
        
        // Auto-execute if threshold reached
        if (grant.approvalCount >= requiredApprovals) {
            executeGrant(grantId);
        }
    }
    
    // Execute a grant after approval threshold is met
    function executeGrant(uint256 grantId) 
        public 
        whenNotPaused 
        nonReentrant 
    {
        require(grantId < grantCount, "Invalid grant ID");
        
        Grant storage grant = grants[grantId];
        
        require(!grant.executed, "Grant already executed");
        require(!grant.canceled, "Grant has been canceled");
        require(grant.approvalCount >= requiredApprovals, "Not enough approvals");
        require(exomemToken.balanceOf(address(this)) >= grant.amount, "Insufficient funds in contract");
        
        grant.executed = true;
        
        require(exomemToken.transfer(grant.recipient, grant.amount), "Token transfer failed");
        
        emit GrantExecuted(grantId, grant.recipient, grant.amount);
    }
    
    // Cancel a grant (only by owner)
    function cancelGrant(uint256 grantId) 
        external 
        onlyOwner 
        whenNotPaused 
    {
        require(grantId < grantCount, "Invalid grant ID");
        
        Grant storage grant = grants[grantId];
        
        require(!grant.executed, "Grant already executed");
        require(!grant.canceled, "Grant already canceled");
        
        grant.canceled = true;
        
        emit GrantCanceled(grantId);
    }
    
    // Add a new approver
    function addApprover(address approver) 
        external 
        onlyOwner 
        whenNotPaused 
    {
        require(approver != address(0), "Invalid approver address");
        require(!approvers[approver], "Already an approver");
        
        approvers[approver] = true;
        approversList.push(approver);
        
        emit ApproverAdded(approver);
    }
    
    // Remove an approver
    function removeApprover(address approver) 
        external 
        onlyOwner 
        whenNotPaused 
    {
        require(approvers[approver], "Not an approver");
        require(approversList.length > requiredApprovals, "Cannot have fewer approvers than required approvals");
        
        approvers[approver] = false;
        
        // Remove from approversList
        for (uint256 i = 0; i < approversList.length; i++) {
            if (approversList[i] == approver) {
                approversList[i] = approversList[approversList.length - 1];
                approversList.pop();
                break;
            }
        }
        
        emit ApproverRemoved(approver);
    }
    
    // Update the required approvals threshold
    function setRequiredApprovals(uint256 newRequiredApprovals) 
        external 
        onlyOwner 
    {
        require(newRequiredApprovals > 0, "Required approvals must be positive");
        require(newRequiredApprovals <= approversList.length, "Required approvals cannot exceed number of approvers");
        
        requiredApprovals = newRequiredApprovals;
        
        emit RequiredApprovalsUpdated(newRequiredApprovals);
    }
    
    // Get grant details (since mappings with nested mappings cannot be returned directly)
    function getGrantInfo(uint256 grantId) 
        external 
        view 
        returns (GrantInfo memory) 
    {
        require(grantId < grantCount, "Invalid grant ID");
        
        Grant storage grant = grants[grantId];
        
        return GrantInfo({
            id: grant.id,
            recipient: grant.recipient,
            amount: grant.amount,
            description: grant.description,
            ipfsHash: grant.ipfsHash,
            approvalCount: grant.approvalCount,
            executed: grant.executed,
            canceled: grant.canceled
        });
    }
    
    // Check if an address has approved a specific grant
    function hasApproved(uint256 grantId, address approver) 
        external 
        view 
        returns (bool) 
    {
        require(grantId < grantCount, "Invalid grant ID");
        return grants[grantId].approvals[approver];
    }
    
    // Get the total number of approvers
    function getApproverCount() 
        external 
        view 
        returns (uint256) 
    {
        return approversList.length;
    }
    
    // Pause fund operations in emergency
    function pause() 
        external 
        onlyOwner 
    {
        _pause();
    }
    
    // Unpause fund operations
    function unpause() 
        external 
        onlyOwner 
    {
        _unpause();
    }
    
    // Emergency withdrawal of tokens
    function emergencyWithdraw(uint256 amount) 
        external 
        onlyOwner 
        nonReentrant 
    {
        require(amount > 0, "Amount must be greater than zero");
        require(amount <= exomemToken.balanceOf(address(this)), "Insufficient balance");
        
        require(exomemToken.transfer(owner(), amount), "Token transfer failed");
    }
}
