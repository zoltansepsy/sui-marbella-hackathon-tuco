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

// ======== Deployment Instructions ========
// 1. Deploy contracts: cd move/zk_freelance && sui client publish --gas-budget 100000000 .
// 2. Copy the package ID from the output
// 3. Update all three constants above with the same package ID
// 4. The package contains all modules: job_escrow, profile_nft, reputation, milestone
