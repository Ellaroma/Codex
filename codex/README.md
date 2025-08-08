# Codex

A decentralized marketplace for verified and audited smart contracts on the Stacks blockchain.

## Overview

Codex is a comprehensive smart contract registry that enables developers to submit, verify, and monetize their smart contracts while providing a trusted marketplace for others to purchase and deploy audited code. The platform creates a sustainable ecosystem where auditors are incentivized to verify high-quality contracts, and developers can safely acquire battle-tested smart contract templates.

## Key Features

### 🔍 **Contract Verification**
- Submit smart contracts for professional auditing
- Immutable verification status with auditor attribution
- IPFS integration for source code storage
- Categorized by use case (DeFi, NFT, DAO, Identity, Utility)

### 💰 **Dual Licensing Model**
- **Template License**: Full ownership rights with unlimited deployment
- **Usage License**: Pay-per-deployment model for cost-effective access
- Flexible pricing set by contract auditors

### 🏆 **Quality Assurance**
- Community-driven evaluation system (1-5 star trust ratings)
- Only verified license holders can evaluate contracts
- Transparent feedback and review system

### 💸 **Revenue Sharing**
- Automatic revenue distribution to auditors
- 4% platform fee (configurable by admin)
- Direct payment claiming for auditors

## Contract Architecture

### Core Data Structures

**Verified Contracts**
```clarity
{
  auditor: principal,
  contract-title: string,
  contract-description: string,
  use-case: string,
  license-cost: uint,
  template-cost: uint,
  deployment-count: uint,
  contract-revenue: uint,
  verified: bool,
  source-reference: string
}
```

**Developer Licenses**
```clarity
{
  license-model: string,
  purchased-at: uint,
  usage-limit: uint,
  amount-paid: uint
}
```

## How It Works

### For Auditors/Developers
1. **Submit Contract**: Upload contract with metadata and pricing
2. **Verification**: Mark as verified after thorough audit
3. **Monetization**: Earn revenue from license sales
4. **Payment**: Claim accumulated earnings anytime

### For Buyers
1. **Browse**: Explore verified contracts by category
2. **Purchase**: Choose between template or usage license
3. **Deploy**: Use licensed contracts in your projects
4. **Evaluate**: Rate and review deployed contracts

## Usage Examples

### Submit a Contract for Verification
```clarity
(contract-call? .codex submit-contract
  "QmX7b2c..." ;; contract hash
  u"DeFi Yield Farming Pool" ;; title
  u"Automated yield farming with compound rewards" ;; description
  "defi" ;; use case
  u1000000 ;; license cost (1 STX per deployment)
  u50000000 ;; template cost (50 STX for full rights)
  "QmY8d3f..." ;; IPFS source hash
)
```

### Purchase Template Rights
```clarity
(contract-call? .codex purchase-template "QmX7b2c...")
```

### Purchase Usage License
```clarity
(contract-call? .codex purchase-license "QmX7b2c..." u10) ;; 10 deployments
```

### Deploy Licensed Contract
```clarity
(contract-call? .codex deploy-contract "QmX7b2c...")
```

### Evaluate Contract
```clarity
(contract-call? .codex evaluate-contract
  "QmX7b2c..."
  u5 ;; 5-star rating
  u"Excellent contract, deployed smoothly with great documentation"
)
```

## Contract Categories

- **DeFi**: Decentralized finance protocols
- **NFT**: Non-fungible token contracts
- **DAO**: Decentralized governance systems
- **Identity**: Digital identity and authentication
- **Utility**: General-purpose utility contracts

## Security Features

- **Access Control**: Strict permission management
- **Payment Validation**: Secure STX transfer handling
- **Usage Tracking**: Automatic deployment counting
- **Immutable Records**: Blockchain-based audit trail

## Economic Model

- **Registry Fee**: 4% of all transactions (adjustable by admin)
- **Auditor Revenue**: 96% of license sales
- **Flexible Pricing**: Auditors set their own rates
- **Usage Limits**: Granular control over deployment rights

## Getting Started

1. Deploy the Codex contract to Stacks testnet/mainnet
2. Submit your first smart contract for verification
3. Set competitive pricing for licenses
4. Market your verified contracts to the community
5. Earn passive income from license sales

## Development Roadmap

- [ ] Web interface for contract browsing
- [ ] Integration with popular Stacks wallets
- [ ] Advanced search and filtering
- [ ] Batch license purchases
- [ ] Contract update notifications
- [ ] Multi-signature auditor approvals

## Contributing

We welcome contributions from the Stacks community. Please submit issues and pull requests to help improve Codex.

## License

This project is open source. Individual smart contracts in the registry maintain their own licensing terms as set by their respective auditors.

---

*Codex - Building trust in the decentralized economy, one verified contract at a time.*