import { getFullnodeUrl } from "@mysten/sui/client";
import {
  DEVNET_JOB_ESCROW_PACKAGE_ID,
  TESTNET_JOB_ESCROW_PACKAGE_ID,
  MAINNET_JOB_ESCROW_PACKAGE_ID,
  DEVNET_PROFILE_NFT_PACKAGE_ID,
  TESTNET_PROFILE_NFT_PACKAGE_ID,
  MAINNET_PROFILE_NFT_PACKAGE_ID,
  DEVNET_REPUTATION_PACKAGE_ID,
  TESTNET_REPUTATION_PACKAGE_ID,
  MAINNET_REPUTATION_PACKAGE_ID,
} from "./constants";
import { createNetworkConfig } from "@mysten/dapp-kit";

const { networkConfig, useNetworkVariable, useNetworkVariables } =
  createNetworkConfig({
    devnet: {
      url: getFullnodeUrl("devnet"),
      variables: {
        jobEscrowPackageId: DEVNET_JOB_ESCROW_PACKAGE_ID,
        profileNftPackageId: DEVNET_PROFILE_NFT_PACKAGE_ID,
        reputationPackageId: DEVNET_REPUTATION_PACKAGE_ID,
      },
    },
    testnet: {
      url: getFullnodeUrl("testnet"),
      variables: {
        jobEscrowPackageId: TESTNET_JOB_ESCROW_PACKAGE_ID,
        profileNftPackageId: TESTNET_PROFILE_NFT_PACKAGE_ID,
        reputationPackageId: TESTNET_REPUTATION_PACKAGE_ID,
      },
    },
    mainnet: {
      url: getFullnodeUrl("mainnet"),
      variables: {
        jobEscrowPackageId: MAINNET_JOB_ESCROW_PACKAGE_ID,
        profileNftPackageId: MAINNET_PROFILE_NFT_PACKAGE_ID,
        reputationPackageId: MAINNET_REPUTATION_PACKAGE_ID,
      },
    },
  });

export { useNetworkVariable, useNetworkVariables, networkConfig };
