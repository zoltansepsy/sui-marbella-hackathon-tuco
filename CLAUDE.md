# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Next.js dApp built on the Sui blockchain that demonstrates integration with **Walrus** (decentralized storage) and **Seal** (Identity-Based Encryption with whitelist access control). The project showcases secure file storage with encrypted access control patterns.

## Core Technologies

- **Frontend**: Next.js 16.0.3 with React 19.2.0, TypeScript, Tailwind CSS 4.1.17
- **Blockchain**: Sui blockchain (testnet)
- **Storage**: Walrus decentralized storage network (@mysten/walrus SDK)
- **Encryption**: Seal Identity-Based Encryption (@mysten/seal SDK)
- **UI**: Radix UI components with shadcn/ui patterns
- **State Management**: @tanstack/react-query for data fetching
- **Wallet**: @mysten/dapp-kit for wallet connections

## Development Commands

```bash
# Install dependencies
pnpm install

# Development server (http://localhost:3000)
pnpm dev

# Production build
pnpm build

# Start production server
pnpm start

# Linting
pnpm lint
pnpm lint:fix
```

## Smart Contract Development

### Move Package Location
- All Move smart contracts are in [move/startHack/](move/startHack/)
- Package name: `startHack`
- Modules: `counter` and `whitelist`

### Deploying Smart Contracts

```bash
# Navigate to Move directory
cd move/startHack

# Build (check for errors)
sui move build

# Test
sui move test

# Deploy to testnet
sui client publish --gas-budget 100000000 .

# After deployment, update constants.ts with the new package ID
```

### Important: After Deployment
Always update [app/constants.ts](app/constants.ts) with the new package ID:
```typescript
export const TESTNET_WHITELIST_PACKAGE_ID = "0xYOUR_NEW_PACKAGE_ID";
```

## Architecture Overview

### Service Layer Pattern
The project uses a clean service layer architecture with three primary services in [app/services/](app/services/):

1. **WalrusService** ([walrusServiceSDK.ts](app/services/walrusServiceSDK.ts))
   - Uses official @mysten/walrus SDK
   - **CRITICAL**: Must use `SuiJsonRpcClient` (not `SuiClient`) with `network` property
   - Handles file upload/download to Walrus decentralized storage
   - Uses `writeFilesFlow` for browser environments (avoids popup blocking)
   - Flow steps: encode → register → upload → certify

2. **SealService** ([sealService.ts](app/services/sealService.ts))
   - Uses @mysten/seal SDK for Identity-Based Encryption
   - Manages encryption/decryption with whitelist access control
   - Uses SessionKey pattern (10-minute TTL) to avoid repeated wallet confirmations
   - ID format: `[packageId][whitelistObjectId][nonce]`

3. **WhitelistService** ([whitelistService.ts](app/services/whitelistService.ts))
   - Manages on-chain whitelist objects
   - Handles Cap (admin capability) objects
   - Create, add, and remove addresses from whitelists

### Key Components

- [WalrusUpload.tsx](app/WalrusUpload.tsx) - File/text/JSON upload to Walrus
- [SealWhitelist.tsx](app/SealWhitelist.tsx) - Encryption with whitelist access control
- [Navbar.tsx](app/components/Navbar.tsx) - Navigation with wallet connection

### Whitelist Smart Contract Pattern

The [whitelist.move](move/startHack/sources/whitelist.move) contract implements:
- **Whitelist**: Shared object containing allowed addresses
- **Cap**: Owned object granting admin rights to manage the whitelist
- **Access Control**: `seal_approve` validates decryption attempts
- **Key Format**: `[packageId][whitelistObjectId][nonce]`

#### Whitelist ID Construction
When using Seal with whitelist:
1. The ID passed to `SealClient.encrypt()` is: `[whitelistObjectId][nonce]` in hex
2. Seal SDK automatically prepends the `packageId`
3. The Move contract validates the ID has the whitelist object ID as prefix

## Configuration Files

### Critical Configuration
- [app/constants.ts](app/constants.ts) - Package IDs for different networks
- [app/networkConfig.ts](app/networkConfig.ts) - Network configuration for dApp-kit
- [tsconfig.json](tsconfig.json) - Path alias: `@/*` → `./app/*`
- [move/startHack/Move.toml](move/startHack/Move.toml) - Move package configuration

## Walrus Integration Notes

### Upload Flow (Browser Environment)
The `uploadWithFlow` method breaks upload into steps to avoid browser popup blocking:
```typescript
const flow = walrus.uploadWithFlow([file], { epochs, deletable });
await flow.encode();
const registerTx = flow.register({ owner, epochs, deletable });
// Sign and execute registerTx
await flow.upload({ digest });
const certifyTx = flow.certify();
// Sign and execute certifyTx
const files = await flow.listFiles();
```

### Important Walrus Details
- BlobId vs Metadata ID: Extract metadata ID from `BlobRegistered` event for explorer links
- Storage duration: Set in epochs (10 epochs ≈ 30 days on testnet)
- Aggregator URL: `https://aggregator.walrus-testnet.walrus.space/v1/`
- Explorer: WalrusCan (https://walruscan.com/testnet/blob/{blobId})

## Seal Integration Notes

### Session Key Pattern
Session keys allow decryption for 10 minutes without repeated wallet signatures:
```typescript
const sessionKey = await sealService.createSessionKey(address, signPersonalMessage);
// Use for multiple decryptions within 10 minutes
const decrypted = await sealService.decrypt(encrypted, sessionKey, whitelistId, nonce);
```

### Seal Server Selection
Multiple Seal key servers available on testnet (in [sealService.ts:10-29](app/services/sealService.ts)):
- Default: "Mysten Testnet 1"
- Configurable at runtime in UI

### Encryption ID Format
- ID = `[whitelistObjectId][nonce]` (hex bytes)
- Seal SDK prepends packageId automatically
- Move contract validates: `wl.id.to_bytes()` must be prefix of ID

## Common Patterns

### Transaction Pattern
```typescript
const tx = new Transaction();
tx.moveCall({
  arguments: [tx.object(id), tx.pure.u64(value)],
  target: `${packageId}::module::function`,
});
signAndExecute({ transaction: tx }, {
  onSuccess: async ({ digest }) => {
    await suiClient.waitForTransaction({ digest });
    // Handle success
  }
});
```

### Object Query Pattern
```typescript
const { data, refetch } = useSuiClientQuery("getObject", {
  id: objectId,
  options: { showContent: true }
});
```

## Troubleshooting

### Common Issues

**"Package not found"**: Verify package ID in [constants.ts](app/constants.ts) matches deployed package

**Walrus upload fails**:
- Check wallet is connected
- Ensure using `writeFilesFlow` for browser (not direct `writeFiles`)
- Verify network matches (testnet)

**Seal decryption fails**:
- Verify address is on the whitelist
- Check session key hasn't expired (10 min TTL)
- Ensure correct whitelistObjectId and nonce
- Validate Seal server selection

**Transaction fails**:
- Check gas budget (100000000 for contract deployment)
- Verify wallet has sufficient SUI
- Ensure connected to correct network (testnet)

## Testing Strategy

When testing Walrus/Seal integration:
1. Create a whitelist first
2. Add test addresses to whitelist
3. Create session key before decryption
4. Use same whitelistId and nonce for encrypt/decrypt pairs
5. Monitor browser console for detailed logs (encryption/decryption show bytes)

## Dependencies Notes

- **@mysten/walrus**: Requires `SuiJsonRpcClient` with `network` property
- **@mysten/seal**: Requires wallet's `signPersonalMessage` feature
- **@mysten/dapp-kit**: Provides wallet hooks and UI components
- **Next.js 16**: Uses App Router, all pages are client components with `"use client"`
- **pnpm**: Required package manager (specified in package.json)
