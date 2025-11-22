// ======== Example Contracts ========

export const DEVNET_COUNTER_PACKAGE_ID = "0xbce15267365bebfd0267e4789406ec89ba7901e687301da0d3fdb6d3e5be81fb";
export const TESTNET_COUNTER_PACKAGE_ID = "0xTODO_AFTER_DEPLOY";
export const MAINNET_COUNTER_PACKAGE_ID = "0xTODO";

export const DEVNET_WHITELIST_PACKAGE_ID = "0xbce15267365bebfd0267e4789406ec89ba7901e687301da0d3fdb6d3e5be81fb";
export const TESTNET_WHITELIST_PACKAGE_ID = "0xTODO_AFTER_DEPLOY";
export const MAINNET_WHITELIST_PACKAGE_ID = "0xTODO";

// ======== Freelance Platform Contracts ========
// NOTE: Update these after deploying the contracts!

/**
 * Job Escrow Package IDs
 * Deploy with: cd move/zk_freelance && sui client publish --gas-budget 100000000 .
 */
export const DEVNET_JOB_ESCROW_PACKAGE_ID = "0xbce15267365bebfd0267e4789406ec89ba7901e687301da0d3fdb6d3e5be81fb";
export const TESTNET_JOB_ESCROW_PACKAGE_ID = "0xTODO_AFTER_DEPLOY";
export const MAINNET_JOB_ESCROW_PACKAGE_ID = "0xTODO";

/**
 * Profile NFT Package IDs
 * Uses same package as job_escrow (part of zk_freelance package)
 */
export const DEVNET_PROFILE_NFT_PACKAGE_ID = "0xbce15267365bebfd0267e4789406ec89ba7901e687301da0d3fdb6d3e5be81fb";
export const TESTNET_PROFILE_NFT_PACKAGE_ID = "0xTODO_AFTER_DEPLOY";
export const MAINNET_PROFILE_NFT_PACKAGE_ID = "0xTODO";

/**
 * Reputation Package IDs
 * Uses same package as job_escrow (part of zk_freelance package)
 */
export const DEVNET_REPUTATION_PACKAGE_ID = "0xbce15267365bebfd0267e4789406ec89ba7901e687301da0d3fdb6d3e5be81fb";
export const TESTNET_REPUTATION_PACKAGE_ID = "0xTODO_AFTER_DEPLOY";
export const MAINNET_REPUTATION_PACKAGE_ID = "0xTODO";

/**
 * Identity Registry Object IDs
 * Shared object created during profile_nft module initialization (init function)
 * Maps zkLogin OAuth subject IDs to Profile IDs for global lookup
 *
 * IMPORTANT: After deployment, find the IdentityRegistry object ID from deployment output
 * Look for: "Created Objects" -> type ending in "::profile_nft::IdentityRegistry"
 */
export const DEVNET_IDENTITY_REGISTRY_ID = "0xda209d1512a8c32cb09914736768f2405dd093163bb6802475c4cc3e64366558";
export const TESTNET_IDENTITY_REGISTRY_ID = "0xTODO_AFTER_DEPLOY";
export const MAINNET_IDENTITY_REGISTRY_ID = "0xTODO";

// ======== Deployment Instructions ========
// 1. Deploy contracts: cd move/zk_freelance && sui client publish --gas-budget 100000000 .
// 2. Copy the package ID from the output
// 3. Update all package ID constants above with the same package ID
// 4. Find the IdentityRegistry shared object ID from "Created Objects" in deployment output
// 5. Update IDENTITY_REGISTRY_ID constants with the registry object ID
// 6. The package contains all modules: job_escrow, profile_nft, reputation, milestone

// ======== zkLogin Configuration ========

/**
 * Google OAuth Client ID
 * Get from: https://console.cloud.google.com/apis/credentials
 * Make sure to add http://localhost:3000/auth/callback to authorized redirect URIs
 *
 * IMPORTANT: Replace this with your actual Google OAuth Client ID
 * You can also set it via environment variable: NEXT_PUBLIC_GOOGLE_CLIENT_ID
 */
export const GOOGLE_CLIENT_ID = process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID || "414212044936-v5htej4oaapbrchs0uc1tlf60gqils4f.apps.googleusercontent.com";

/**
 * zkLogin Prover URL (Mysten's prover service for devnet)
 */
export const PROVER_URL = "https://prover-dev.mystenlabs.com/v1";

/**
 * OAuth Redirect URL (must match Google OAuth settings)
 * IMPORTANT: This must match the redirect URI configured in Google OAuth
 */
export const REDIRECT_URL = "http://localhost:3000/auth/callback";

/**
 * OpenID Provider URL for Google
 */
export const OPENID_PROVIDER_URL = "https://accounts.google.com/.well-known/openid-configuration";                       