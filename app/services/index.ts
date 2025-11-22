/**
 * Service Layer
 *
 * This module exports all blockchain and storage services.
 * Services handle all external API calls and blockchain interactions,
 * keeping components clean and focused on UI logic.
 */

// Counter service (example)
export { CounterService, createCounterService } from "./counterService";

// Storage services
export {
  WalrusService,
  createWalrusService,
  type WalrusConfig,
} from "./walrusServiceSDK";

// Encryption services
export { SealService, createSealService, SEAL_TESTNET_SERVERS } from "./sealService";
export {
  WhitelistService,
  createWhitelistService,
  type WhitelistData,
  type CapData,
} from "./whitelistService";

// Freelance platform services
export { JobService, createJobService } from "./jobService";
export { JobEventIndexer, createJobEventIndexer } from "./jobEventIndexer";
export { ProfileService, createProfileService } from "./profileService";
export { ReputationService, createReputationService } from "./reputationService";

// Types
export { getCounterFields, getJobFields, getProfileFields, vectorU8ToString } from "./types";
export type { CounterData, CounterFields } from "./types";
export type {
  JobData,
  JobCapData,
  JobState,
  MilestoneData,
  ProfileData,
  ProfileCapData,
  ProfileType,
  RatingData,
  BadgeData,
  BadgeTier,
} from "./types";
export type {
  JobEventData,
  JobEventQueryResult,
  JobCreatedEvent,
  JobStateChangedEvent,
  FreelancerAssignedEvent,
} from "./jobEventIndexer";
