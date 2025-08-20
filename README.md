
# EXOMEM: Community-Driven Token for the Exoverse Ecosystem

EXOMEM is a community-driven promotional token designed to foster engagement and incentivize early users within the **Exoverse** ecosystem. Built on the Ethereum blockchain, EXOMEM serves as a critical entry point for decentralized finance (DeFi) and governance within Exoverse. This repository contains the smart contracts for the EXOMEM token and the associated ecosystem components, including governance, rewards, and grants.

## Table of Contents
1. [Project Overview](#project-overview)
2. [Smart Contracts](#smart-contracts)
   - [ExomemToken.sol](#exomemtokensol)
   - [ExomemRewards.sol](#exomemrewardssol)
   - [ExomemGovernance.sol](#exomemgovernancesol)
   - [ExomemEcosystemFund.sol](#exomemecosystemfundsol)
   - [ExomemSecurityFund.sol](#exomemsecurityfundsol)
3. [Tokenomics](#tokenomics)
4. [How to Deploy](#how-to-deploy)
5. [Contributing](#contributing)
6. [License](#license)

## Project Overview

EXOMEM is a utility token built to incentivize the **Exoverse** ecosystem. It plays a pivotal role in spreading awareness, rewarding users, and driving adoption for decentralized applications (dApps) and governance within Exoverse.

## Smart Contracts

### ExomemToken.sol
This contract defines the core **EXOMEM** token, implementing the ERC20 standard with additional functionality for governance, security, and pausing operations in emergencies.

**Features:**
- Minting and token distribution.
- Burn functionality to allow users to destroy tokens.
- Pausable feature to halt token transfers during emergencies.
- Token distribution: 35% for Meme Movement & Contests, 30% for Startups & Ecosystem Development, 20% for Governance & Treasury, 7% for Security Fund, 5% for Developers & Partners, 3% for Guardians & Security.

```solidity
contract ExomemToken is ERC20, Ownable, Pausable {
    // Wallet addresses
    address public immutable governanceWallet = 0x5771cEAA8061c6b04c1bE3d5d9D70Cb5E9c08C2a;
    address public immutable airdropWallet = 0xaF0Ab6b455fA4c3C9dbbB2E3F69eFAB3303456d9;
    address public immutable securityFundWallet = 0x7ACEdd52927e780F69Acb2c1b2910933d26FB90b;
    address public immutable startupsEcosystemWallet = 0x5EFc357FE0B8f777136183818e0161A08a74D370;
    address public immutable developersPartnersWallet = 0x934eb5119aee67b358b9eE938E0871F0781C3890;
    address public immutable guardiansWallet = 0xc4B74939a289B8f824E2ab6cD25Bb9C5dcC032FC;

    uint256 private constant TOTAL_SUPPLY = 30_000_000_000 * 10**18;
}
```

### ExomemRewards.sol
Manages the **EXOMEM** rewards program for meme contests and user engagement. This contract allows for contest creation, meme submissions, voting, and reward distribution.

**Features:**
- Create and manage meme contests.
- Submit content and vote for submissions.
- Distribute rewards based on contest results.

```solidity
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
}
```

### ExomemGovernance.sol
This contract governs decision-making within the Exoverse ecosystem. It allows for the creation of proposals, voting by token holders, and execution of decisions after the proposal has been approved.

**Features:**
- Create proposals.
- Vote for proposals.
- Execute proposals after approval.

```solidity
contract ExomemGovernance is Ownable, ReentrancyGuard, Pausable {
    IERC20 public immutable exomemToken;

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 startTime;
        uint256 endTime;
        bool executed;
    }
}
```

### ExomemEcosystemFund.sol
Manages grants and funding for the development and growth of the Exoverse ecosystem. This contract allows for the proposal, approval, and distribution of grants to recipients.

**Features:**
- Propose and approve grants.
- Execute grants when required approvals are met.

```solidity
contract ExomemEcosystemFund is Ownable, ReentrancyGuard, Pausable {
    IERC20 public immutable exomemToken;

    struct Grant {
        uint256 id;
        address recipient;
        uint256 amount;
        string description;
        bool executed;
        bool canceled;
    }
}
```

### ExomemSecurityFund.sol
Handles emergency security actions, such as audits or bug bounties, within the Exoverse ecosystem. Actions can be proposed by a security council and require approvals before execution.

**Features:**
- Propose, approve, and execute security actions.
- Automatic approval based on predefined thresholds.

```solidity
contract ExomemSecurityFund is Ownable, ReentrancyGuard, Pausable {
    IERC20 public immutable exomemToken;

    struct SecurityAction {
        uint256 id;
        string actionType;
        address recipient;
        uint256 amount;
        string description;
        bool executed;
        bool canceled;
    }
}
```

## Tokenomics

EXOMEM has a total supply of 30 billion tokens. The tokenomics is structured to encourage adoption and sustainability within the Exoverse ecosystem:

- **35% - Meme Movement & Contests**  
  *Wallet address:* [Airdrop Wallet](0xaF0Ab6b455fA4c3C9dbbB2E3F69eFAB3303456d9)
  
- **30% - Startups & Ecosystem Development**  
  *Wallet address:* [Startups & Ecosystem Wallet](0x5EFc357FE0B8f777136183818e0161A08a74D370)

- **20% - Governance & Treasury**  
  *Wallet address:* [Governance Wallet](0x5771cEAA8061c6b04c1bE3d5d9D70Cb5E9c08C2a)

- **7% - Security Fund (NoOne Vault)**  
  *Wallet address:* [Security Fund Wallet](0x7ACEdd52927e780F69Acb2c1b2910933d26FB90b)

- **5% - Developers & Partners**  
  *Wallet address:* [Developers & Partners Wallet](0x934eb5119aee67b358b9eE938E0871F0781C3890)

- **3% - Guardians & Security**  
  *Wallet address:* [Guardians Wallet](0xc4B74939a289B8f824E2ab6cD25Bb9C5dcC032FC)

## How to Deploy

1. Clone this repository:
   ```bash
   git clone https://github.com/exogov/EXOMEM.git
   cd EXOMEM
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Deploy the contracts using Hardhat or Truffle:
   ```bash
   npx hardhat run scripts/deploy.js --network <network>
   ```

## Contributing

We welcome contributions! Please feel free to open issues or submit pull requests. Here's how you can help:

- Bug fixes or feature enhancements.
- Write tests for new and existing contracts.
- Improve documentation.

## License

This document, **"The Constitution of Exoverse"** and **"Exoverse Whitepaper"**, is licensed under the [GNU General Public License (GPL-3.0)](https://www.gnu.org/licenses/gpl-3.0.html).

You may copy, modify, and distribute this document under the terms of the GPL-3.0 License, but any modified versions must also be distributed under the same license.

*No warranty is provided* for the contents of this document, and the authors are not responsible for any misuse or consequences resulting from its use.
