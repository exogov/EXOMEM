// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract ExomemToken is ERC20, Ownable, Pausable {
    // Wallet addresses
    address public immutable governanceWallet = 0x5771cEAA8061c6b04c1bE3d5d9D70Cb5E9c08C2a;
    address public immutable airdropWallet = 0xaF0Ab6b455fA4c3C9dbbB2E3F69eFAB3303456d9;
    address public immutable securityFundWallet = 0x7ACEdd52927e780F69Acb2c1b2910933d26FB90b;
    address public immutable startupsEcosystemWallet = 0x5EFc357FE0B8f777136183818e0161A08a74D370;
    address public immutable developersPartnersWallet = 0x934eb5119aee67b358b9eE938E0871F0781C3890;
    address public immutable guardiansWallet = 0xc4B74939a289B8f824E2ab6cD25Bb9C5dcC032FC;
    
    // Total supply: 30 billion tokens
    uint256 private constant TOTAL_SUPPLY = 30_000_000_000 * 10**18;
    
    // Events
    event TokensBurned(address indexed burner, uint256 amount);
    
    constructor() ERC20("Exomem", "EX0") Ownable(msg.sender) {
        // Mint all tokens to the contract owner
        _mint(msg.sender, TOTAL_SUPPLY);
        
        // Distribute tokens according to the allocation
        // 35% to Meme Movement & Contests
        _transfer(msg.sender, airdropWallet, TOTAL_SUPPLY * 35 / 100);
        
        // 30% to Startups & Ecosystem Development
        _transfer(msg.sender, startupsEcosystemWallet, TOTAL_SUPPLY * 30 / 100);
        
        // 20% to Governance & Treasury
        _transfer(msg.sender, governanceWallet, TOTAL_SUPPLY * 20 / 100);
        
        // 7% to Security Fund (NoOne Vault)
        _transfer(msg.sender, securityFundWallet, TOTAL_SUPPLY * 7 / 100);
        
        // 5% to Developers & Partners
        _transfer(msg.sender, developersPartnersWallet, TOTAL_SUPPLY * 5 / 100);
        
        // 3% to Guardians & Security
        _transfer(msg.sender, guardiansWallet, TOTAL_SUPPLY * 3 / 100);
    }
    
    // Burn function to allow token burning
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }
    
    // Pause token transfers in emergency
    function pause() external onlyOwner {
        _pause();
    }
    
    // Unpause token transfers
    function unpause() external onlyOwner {
        _unpause();
    }
    
    // Override transfer function to respect paused state
    function _update(address from, address to, uint256 amount) internal virtual override whenNotPaused {
        super._update(from, to, amount);
    }
}