# Gignova - Zero-Knowledge Freelance Platform

A decentralized freelance marketplace built on the Sui blockchain that solves the atomic swap problem in freelance work through cryptographic guarantees.

## 🎯 What is Gignova?

Gignova is a trustless freelance platform where clients and freelancers can work together without intermediaries. The platform ensures that:
- **Clients** never pay before seeing proof of work
- **Freelancers** never deliver work before receiving payment
- **Both parties** are protected through blockchain-enforced escrow

## 🔐 Core Technology

### Seal - Identity-Based Encryption
Gignova uses **Seal** (Sui's Identity-Based Encryption SDK) to encrypt deliverables. Work is encrypted with the client's address, ensuring only they can decrypt it after payment is released from escrow.

**How it works:**
1. Client posts a job/gig description
2. Freelancers apply for job
3. Client chooses freelancer
3. Freelancer completes work
2. Work is encrypted using Seal with client's address
3. Encrypted file is uploaded to Walrus
4. Client can only decrypt after approving the milestone and releasing payment

### Walrus - Decentralized Storage
All job descriptions and encrypted deliverables are stored on **Walrus**, Sui's decentralized storage network, ensuring:
- **Permanence**: Files cannot be deleted or tampered with
- **Availability**: Content is always accessible through the distributed network
- **Efficiency**: Pay-once storage model with blob IDs for on-chain reference

## 🏗️ Architecture

### Smart Contracts (Move)
- **Job Escrow**: Manages job lifecycle, milestones, and payment escrow
- **Profile NFT**: Dynamic on-chain profiles with reputation and badges
- **Reputation System**: Rating and review mechanism
- **Milestone Tracking**: Break jobs into verifiable stages

### Workflow
1. **Client posts job** → Description stored on Walrus, escrow created
2. **Freelancer applies** → Profile-based matching
3. **Work begins** → State transitions tracked on-chain
4. **Deliverable submitted** → Encrypted with Seal, stored on Walrus, watermarked preview provided
5. **Client reviews preview** → Can verify quality without accessing full work
6. **Milestone approved** → Payment released from escrow
7. **Freelancer shares key** → Client decrypts full deliverables using Seal
8. **Mutual rating** → On-chain reputation updated

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- pnpm package manager
- Sui Wallet browser extension

### Installation
```bash
# Clone repository
git clone <repository-url>
cd sui-marbella-hackathon-tuco

# Install dependencies
pnpm install

# Start development server
pnpm dev
```

Visit `http://localhost:3000` to access the platform.

### Smart Contract Deployment
```bash
# Navigate to Move package
cd move/zk_freelance

# Build contracts
sui move build

# Deploy to testnet
sui client publish --gas-budget 100000000 .

# Update package ID in app/constants.ts
```

## 📦 Tech Stack

- **Frontend**: Next.js 16, React 19, TypeScript, Tailwind CSS
- **Blockchain**: Sui (Move smart contracts)
- **Storage**: Walrus SDK (@mysten/walrus)
- **Encryption**: Seal SDK (@mysten/seal)
- **Wallet**: @mysten/dapp-kit
- **State**: @tanstack/react-query

## 🔑 Key Features

### For Freelancers
- Create profile NFT with skills and portfolio
- Browse open jobs in marketplace
- Submit encrypted deliverables with previews
- Build on-chain reputation
- Earn achievement badges

### For Clients
- Post jobs with milestone-based payments
- Review encrypted previews before payment
- Escrow protection with smart contracts
- Rate freelancers after completion
- JobCap NFT for job management

### Security Guarantees
- ✅ Payment locked in escrow until approval
- ✅ Work encrypted until payment released
- ✅ Immutable on-chain reputation
- ✅ Decentralized storage prevents censorship
- ✅ No central authority can freeze funds

## 🎓 Learn More

- [Sui Documentation](https://docs.sui.io)
- [Walrus Documentation](https://docs.walrus.site)
- [Seal Documentation](https://docs.sui.io/standards/seal)
- [Move Language](https://move-language.github.io/move/)

## 📄 Project Structure

```
├── app/                    # Next.js application
│   ├── components/        # React components
│   ├── services/          # Blockchain integration
│   └── hooks/             # Custom React hooks
├── move/zk_freelance/     # Move smart contracts
│   ├── sources/           # Contract modules
│   └── Move.toml          # Package configuration
└── public/                # Static assets
```

## 🛠️ Development

```bash
# Run development server
pnpm dev

# Build for production
pnpm build

# Run production server
pnpm start

# Lint code
pnpm lint
```

## 🤝 Contributing

This project was built for the Sui Marbella Hackathon. Contributions are welcome!

## 📝 License

MIT License - see LICENSE file for details.

---

**Built with 🔐 Seal and 📦 Walrus on Sui**
