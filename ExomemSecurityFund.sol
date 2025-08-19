// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract ExomemSecurityFund is Ownable, ReentrancyGuard, Pausable {
    IERC20 public immutable exomemToken;
    
    struct SecurityAction {
        uint256 id;
        string actionType; // "audit", "bugBounty", "recovery", etc.
        address recipient;
        uint256 amount;
        string description;
        string ipfsHash; // For detailed information
        uint256 approvalCount;
        bool executed;
        bool canceled;
        mapping(address => bool) approvals;
    }
    
    struct SecurityActionInfo {
        uint256 id;
        string actionType;
        address recipient;
        uint256 amount;
        string description;
        string ipfsHash;
        uint256 approvalCount;
        bool executed;
        bool canceled;
    }
    
    // Mapping from action ID to SecurityAction
    mapping(uint256 => SecurityAction) private securityActions;
    
    // Total number of security actions
    uint256 public actionCount;
    
    // Security council members who can approve actions
    mapping(address => bool) public councilMembers;
    address[] public councilMembersList;
    
    // Number of approvals required to execute an action
    uint256 public requiredApprovals = 3;
    
    // Cooldown period for emergency actions (default: 24 hours)
    uint256 public emergencyCooldown = 24 hours;
    
    // Mapping to track last emergency action time
    uint256 public lastEmergencyActionTime;
    
    // Events
    event SecurityActionProposed(uint256 indexed actionId, string actionType, address indexed recipient, uint256 amount);
    event SecurityActionApproved(uint256 indexed actionId, address indexed approver);
    event SecurityActionExecuted(uint256 indexed actionId, address indexed recipient, uint256 amount);
    event SecurityActionCanceled(uint256 indexed actionId);
    event CouncilMemberAdded(address indexed member);
    event CouncilMemberRemoved(address indexed member);
    event RequiredApprovalsUpdated(uint256 newValue);
    event EmergencyCooldownUpdated(uint256 newValue);
    
    constructor(address _tokenAddress) Ownable(msg.sender) {
        exomemToken = IERC20(_tokenAddress);
        
        // Add owner as initial council member
        councilMembers[owner()] = true;
        councilMembersList.push(owner());
    }
    
    // Propose a new security action
    function proposeSecurityAction(
        string memory actionType,
        address recipient,
        uint256 amount,
        string memory description,
        string memory ipfsHash
    ) 
        external 
        whenNotPaused 
    {
        require(councilMembers[msg.sender], "Not a council member");
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be positive");
        require(amount <= exomemToken.balanceOf(address(this)), "Insufficient funds in contract");
        
        uint256 actionId = actionCount;
        
        SecurityAction storage newAction = securityActions[actionId];
        newAction.id = actionId;
        newAction.actionType = actionType;
        newAction.recipient = recipient;
        newAction.amount = amount;
        newAction.description = description;
        newAction.ipfsHash = ipfsHash;
        newAction.approvalCount = 0;
        newAction.executed = false;
        newAction.canceled = false;
        
        actionCount++;
        
        emit SecurityActionProposed(actionId, actionType, recipient, amount);
    }
    
    // Approve a security action
    function approveSecurityAction(uint256 actionId) 
        external 
        whenNotPaused 
    {
        require(councilMembers[msg.sender], "Not a council member");
        require(actionId < actionCount, "Invalid action ID");
        
        SecurityAction storage action = securityActions[actionId];
        
        require(!action.executed, "Action already executed");
        require(!action.canceled, "Action has been canceled");
        require(!action.approvals[msg.sender], "Already approved this action");
        
        action.approvals[msg.sender] = true;
        action.approvalCount++;
        
        emit SecurityActionApproved(actionId, msg.sender);
        
        // Auto-execute if threshold reached
        if (action.approvalCount >= requiredApprovals) {
            executeSecurityAction(actionId);
        }
    }
    
    // Execute a security action after approval threshold is met
    function executeSecurityAction(uint256 actionId) 
        public 
        whenNotPaused 
        nonReentrant 
    {
        require(actionId < actionCount, "Invalid action ID");
        
        SecurityAction storage action = securityActions[actionId];
        
        require(!action.executed, "Action already executed");
        require(!action.canceled, "Action has been canceled");
        require(action.approvalCount >= requiredApprovals, "Not enough approvals");
        require(exomemToken.balanceOf(address(this)) >= action.amount, "Insufficient funds in contract");
        
        action.executed = true;
        
        require(exomemToken.transfer(action.recipient, action.amount), "Token transfer failed");
        
        emit SecurityActionExecuted(actionId, action.recipient, action.amount);
    }
    
    // Cancel a security action
    function cancelSecurityAction(uint256 actionId) 
        external 
        whenNotPaused 
    {
        require(councilMembers[msg.sender], "Not a council member");
        require(actionId < actionCount, "Invalid action ID");
        
        SecurityAction storage action = securityActions[actionId];
        
        require(!action.executed, "Action already executed");
        require(!action.canceled, "Action already canceled");
        
        action.canceled = true;
        
        emit SecurityActionCanceled(actionId);
    }
    
    // Emergency action (with reduced approvals but subject to cooldown)
    function emergencyAction(
        address recipient,
        uint256 amount,
        string memory description
    ) 
        external 
        onlyOwner 
        nonReentrant 
    {
        require(block.timestamp >= lastEmergencyActionTime + emergencyCooldown, "Emergency cooldown period not elapsed");
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be positive");
        require(amount <= exomemToken.balanceOf(address(this)), "Insufficient funds in contract");
        
        lastEmergencyActionTime = block.timestamp;
        
        require(exomemToken.transfer(recipient, amount), "Token transfer failed");
        
        uint256 actionId = actionCount;
        
        SecurityAction storage newAction = securityActions[actionId];
        newAction.id = actionId;
        newAction.actionType = "emergency";
        newAction.recipient = recipient;
        newAction.amount = amount;
        newAction.description = description;
        newAction.approvalCount = requiredApprovals; // Auto-approve
        newAction.executed = true;
        
        actionCount++;
        
        emit SecurityActionExecuted(actionId, recipient, amount);
    }
    
    // Add a new council member
    function addCouncilMember(address member) 
        external 
        onlyOwner 
        whenNotPaused 
    {
        require(member != address(0), "Invalid member address");
        require(!councilMembers[member], "Already a council member");
        
        councilMembers[member] = true;
        councilMembersList.push(member);
        
        emit CouncilMemberAdded(member);
    }
    
    // Remove a council member
    function removeCouncilMember(address member) 
        external 
        onlyOwner 
        whenNotPaused 
    {
        require(councilMembers[member], "Not a council member");
        require(councilMembersList.length > requiredApprovals, "Cannot have fewer council members than required approvals");
        
        councilMembers[member] = false;
        
        // Remove from councilMembersList
        for (uint256 i = 0; i < councilMembersList.length; i++) {
            if (councilMembersList[i] == member) {
                councilMembersList[i] = councilMembersList[councilMembersList.length - 1];
                councilMembersList.pop();
                break;
            }
        }
        
        emit CouncilMemberRemoved(member);
    }
    
    // Update the required approvals threshold
    function setRequiredApprovals(uint256 newRequiredApprovals) 
        external 
        onlyOwner 
    {
        require(newRequiredApprovals > 0, "Required approvals must be positive");
        require(newRequiredApprovals <= councilMembersList.length, "Required approvals cannot exceed number of council members");
        
        requiredApprovals = newRequiredApprovals;
        
        emit RequiredApprovalsUpdated(newRequiredApprovals);
    }
    
    // Update the emergency cooldown period
    function setEmergencyCooldown(uint256 newCooldown) 
        external 
        onlyOwner 
    {
        require(newCooldown >= 1 hours, "Cooldown too short");
        
        emergencyCooldown = newCooldown;
        
        emit EmergencyCooldownUpdated(newCooldown);
    }
    
    // Get security action details
    function getSecurityActionInfo(uint256 actionId) 
        external 
        view 
        returns (SecurityActionInfo memory) 
    {
        require(actionId < actionCount, "Invalid action ID");
        
        SecurityAction storage action = securityActions[actionId];
        
        return SecurityActionInfo({
            id: action.id,
            actionType: action.actionType,
            recipient: action.recipient,
            amount: action.amount,
            description: action.description,
            ipfsHash: action.ipfsHash,
            approvalCount: action.approvalCount,
            executed: action.executed,
            canceled: action.canceled
        });
    }
    
    // Check if a council member has approved a specific action
    function hasApproved(uint256 actionId, address member) 
        external 
        view 
        returns (bool) 
    {
        require(actionId < actionCount, "Invalid action ID");
        return securityActions[actionId].approvals[member];
    }
    
    // Get the total number of council members
    function getCouncilMemberCount() 
        external 
        view 
        returns (uint256) 
    {
        return councilMembersList.length;
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
}