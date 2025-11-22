/**
 * Job Event Indexer Service
 * Implements event-based job discovery pattern for Sui blockchain
 *
 * ARCHITECTURE PATTERN: Event-Based Indexing
 * ==========================================
 * This service implements the industry-standard Sui pattern for marketplace discovery.
 * Instead of querying shared objects directly (which is not possible), we:
 * 1. Query JobCreated events to discover all jobs
 * 2. Query JobStateChanged events to track current state
 * 3. Query FreelancerAssigned events to find freelancer's jobs
 * 4. Optionally fetch full Job object details for current data
 *
 * This pattern is used by all production Sui marketplaces (Kiosk, DEXs, NFT platforms)
 * because it:
 * - Avoids shared object contention
 * - Has zero gas overhead (events are free)
 * - Scales infinitely
 * - Supports flexible filtering/sorting
 *
 * DEV 2 NOTE:
 * This service is called by jobService.ts query methods. The event-based approach
 * means there's a slight delay (<5 seconds) between transaction and event availability.
 * For production, consider running a backend indexer service.
 */

import { SuiClient, SuiEvent, PaginatedEvents } from "@mysten/sui/client";
import { JobData, JobState, vectorU8ToString } from "./types";

/**
 * Event data structures matching Move events
 */

export interface JobCreatedEvent {
  job_id: string;
  client: string;
  title: number[];  // vector<u8>
  description_blob_id: number[];  // vector<u8>
  budget: string;
  deadline: string;
  milestone_count: string;
  state: number;
  timestamp: string;
}

export interface JobStateChangedEvent {
  job_id: string;
  old_state: number;
  new_state: number;
  freelancer: string | null;  // Option<address>
  timestamp: string;
}

export interface FreelancerAssignedEvent {
  job_id: string;
  client: string;
  freelancer: string;
  timestamp: string;
}

export interface FreelancerAppliedEvent {
  job_id: string;
  freelancer: string;
  timestamp: string;
}

/**
 * Job summary from events (lightweight, no need to query Job object)
 */
export interface JobEventData {
  jobId: string;
  client: string;
  title: string;
  descriptionBlobId: string;
  budget: number;
  deadline: number;
  milestoneCount: number;
  state: JobState;
  freelancer?: string;
  timestamp: number;
}

/**
 * Query result with pagination
 */
export interface JobEventQueryResult {
  jobs: JobEventData[];
  nextCursor: string | null;
  hasNextPage: boolean;
}

export class JobEventIndexer {
  private suiClient: SuiClient;
  private packageId: string;

  constructor(suiClient: SuiClient, packageId: string) {
    this.suiClient = suiClient;
    this.packageId = packageId;
  }

  // ======== Event Query Methods ========

  /**
   * Query all JobCreated events with pagination
   * This is the primary method for discovering all jobs in the marketplace
   *
   * @param cursor Pagination cursor (from previous query)
   * @param limit Maximum number of results (default: 50)
   * @returns Job data from events with pagination info
   */
  async queryJobCreatedEvents(
    cursor?: string | null,
    limit: number = 50
  ): Promise<JobEventQueryResult> {
    try {
      const events = await this.suiClient.queryEvents({
        query: {
          MoveEventType: `${this.packageId}::job_escrow::JobCreated`,
        },
        cursor: cursor || undefined,
        limit,
        order: "descending", // Latest jobs first
      });

      const jobs = events.data.map((event) =>
        this.parseJobCreatedEvent(event)
      );

      return {
        jobs,
        nextCursor: events.nextCursor || null,
        hasNextPage: events.hasNextPage,
      };
    } catch (error) {
      console.error("Error querying JobCreated events:", error);
      return {
        jobs: [],
        nextCursor: null,
        hasNextPage: false,
      };
    }
  }

  /**
   * Query jobs created by a specific client
   * Uses the Sender filter to only get events from this client's transactions
   *
   * @param clientAddress Client's wallet address
   * @param limit Maximum number of results
   * @returns Jobs posted by this client
   */
  async queryJobsByClient(
    clientAddress: string,
    limit: number = 50
  ): Promise<JobEventData[]> {
    try {
      const events = await this.suiClient.queryEvents({
        query: {
          MoveEventType: `${this.packageId}::job_escrow::JobCreated`,
          Sender: clientAddress, // Filter by transaction sender
        },
        limit,
        order: "descending",
      });

      return events.data.map((event) => this.parseJobCreatedEvent(event));
    } catch (error) {
      console.error("Error querying jobs by client:", error);
      return [];
    }
  }

  /**
   * Query jobs assigned to a specific freelancer
   * Uses FreelancerAssigned events to find assigned jobs
   *
   * @param freelancerAddress Freelancer's wallet address
   * @param limit Maximum number of results
   * @returns Job IDs assigned to this freelancer
   */
  async queryJobsByFreelancer(
    freelancerAddress: string,
    limit: number = 100
  ): Promise<string[]> {
    try {
      const events = await this.suiClient.queryEvents({
        query: {
          MoveEventType: `${this.packageId}::job_escrow::FreelancerAssigned`,
        },
        limit,
        order: "descending",
      });

      // Filter events where this freelancer was assigned
      const assignedJobs = events.data
        .filter((event) => {
          const data = event.parsedJson as FreelancerAssignedEvent;
          return data.freelancer === freelancerAddress;
        })
        .map((event) => {
          const data = event.parsedJson as FreelancerAssignedEvent;
          return data.job_id;
        });

      return assignedJobs;
    } catch (error) {
      console.error("Error querying jobs by freelancer:", error);
      return [];
    }
  }

  /**
   * Get current job state from events
   * Queries JobStateChanged events to find the latest state
   *
   * @param jobId Job object ID
   * @returns Latest job state or null if no state changes found
   */
  async getJobCurrentState(jobId: string): Promise<JobState | null> {
    try {
      const events = await this.suiClient.queryEvents({
        query: {
          MoveEventType: `${this.packageId}::job_escrow::JobStateChanged`,
        },
        limit: 100,
        order: "descending",
      });

      // Find the most recent state change for this job
      const stateEvent = events.data.find((event) => {
        const data = event.parsedJson as JobStateChangedEvent;
        return data.job_id === jobId;
      });

      if (stateEvent) {
        const data = stateEvent.parsedJson as JobStateChangedEvent;
        return data.new_state as JobState;
      }

      return null;
    } catch (error) {
      console.error("Error getting job state:", error);
      return null;
    }
  }

  /**
   * Build a complete job index from events
   * Queries all JobCreated events and updates states from JobStateChanged events
   * This method is useful for building a complete marketplace index
   *
   * WARNING: This can be slow for large numbers of jobs. Consider pagination.
   *
   * @param maxJobs Maximum number of jobs to index (default: 200)
   * @returns Map of job ID to job data
   */
  async buildJobIndex(maxJobs: number = 200): Promise<Map<string, JobEventData>> {
    const jobIndex = new Map<string, JobEventData>();

    // Query JobCreated events
    let cursor: string | null = null;
    let totalFetched = 0;

    while (totalFetched < maxJobs) {
      const result = await this.queryJobCreatedEvents(
        cursor,
        Math.min(50, maxJobs - totalFetched)
      );

      for (const job of result.jobs) {
        jobIndex.set(job.jobId, job);
      }

      totalFetched += result.jobs.length;

      if (!result.hasNextPage || !result.nextCursor) {
        break;
      }

      cursor = result.nextCursor;
    }

    // Update states from JobStateChanged events
    try {
      const stateEvents = await this.suiClient.queryEvents({
        query: {
          MoveEventType: `${this.packageId}::job_escrow::JobStateChanged`,
        },
        limit: maxJobs,
        order: "descending",
      });

      // Group state changes by job ID and take the most recent
      const latestStates = new Map<string, JobStateChangedEvent>();
      for (const event of stateEvents.data) {
        const data = event.parsedJson as JobStateChangedEvent;
        if (!latestStates.has(data.job_id)) {
          latestStates.set(data.job_id, data);
        }
      }

      // Update job states
      for (const [jobId, stateEvent] of latestStates.entries()) {
        const job = jobIndex.get(jobId);
        if (job) {
          job.state = stateEvent.new_state as JobState;
          if (stateEvent.freelancer) {
            job.freelancer = stateEvent.freelancer;
          }
        }
      }
    } catch (error) {
      console.error("Error updating job states:", error);
    }

    return jobIndex;
  }

  /**
   * Query open jobs (marketplace listings)
   * Gets all JobCreated events and filters for currently open jobs
   *
   * @param limit Maximum number of jobs to fetch
   * @returns Array of open jobs
   */
  async queryOpenJobs(limit: number = 50): Promise<JobEventData[]> {
    // Query recent JobCreated events
    const result = await this.queryJobCreatedEvents(null, limit * 2); // Fetch extra to account for non-open jobs

    // Build map of latest states
    const stateMap = new Map<string, JobState>();
    try {
      const stateEvents = await this.suiClient.queryEvents({
        query: {
          MoveEventType: `${this.packageId}::job_escrow::JobStateChanged`,
        },
        limit: limit * 2,
        order: "descending",
      });

      for (const event of stateEvents.data) {
        const data = event.parsedJson as JobStateChangedEvent;
        if (!stateMap.has(data.job_id)) {
          stateMap.set(data.job_id, data.new_state as JobState);
        }
      }
    } catch (error) {
      console.error("Error fetching state changes:", error);
    }

    // Filter for open jobs
    const openJobs = result.jobs
      .map((job) => {
        // Update state if we have newer info
        const latestState = stateMap.get(job.jobId);
        if (latestState !== undefined) {
          job.state = latestState;
        }
        return job;
      })
      .filter((job) => job.state === JobState.OPEN)
      .slice(0, limit);

    return openJobs;
  }

  /**
   * Query jobs with specific state
   *
   * @param state Job state to filter by
   * @param limit Maximum number of results
   * @returns Jobs in the specified state
   */
  async queryJobsByState(
    state: JobState,
    limit: number = 50
  ): Promise<JobEventData[]> {
    // Get recent jobs
    const result = await this.queryJobCreatedEvents(null, limit * 2);

    // Get state updates
    const stateMap = new Map<string, JobState>();
    try {
      const stateEvents = await this.suiClient.queryEvents({
        query: {
          MoveEventType: `${this.packageId}::job_escrow::JobStateChanged`,
        },
        limit: limit * 2,
        order: "descending",
      });

      for (const event of stateEvents.data) {
        const data = event.parsedJson as JobStateChangedEvent;
        if (!stateMap.has(data.job_id)) {
          stateMap.set(data.job_id, data.new_state as JobState);
        }
      }
    } catch (error) {
      console.error("Error fetching state changes:", error);
    }

    // Filter by state
    const filteredJobs = result.jobs
      .map((job) => {
        const latestState = stateMap.get(job.jobId);
        if (latestState !== undefined) {
          job.state = latestState;
        }
        return job;
      })
      .filter((job) => job.state === state)
      .slice(0, limit);

    return filteredJobs;
  }

  // ======== Event Parsing Methods ========

  /**
   * Parse JobCreated event into JobEventData
   *
   * @param event Sui event object
   * @returns Parsed job data
   */
  private parseJobCreatedEvent(event: SuiEvent): JobEventData {
    const data = event.parsedJson as JobCreatedEvent;

    return {
      jobId: data.job_id,
      client: data.client,
      title: vectorU8ToString(data.title),
      descriptionBlobId: vectorU8ToString(data.description_blob_id),
      budget: Number(data.budget),
      deadline: Number(data.deadline),
      milestoneCount: Number(data.milestone_count),
      state: data.state as JobState,
      timestamp: Number(data.timestamp),
    };
  }

  /**
   * Parse FreelancerAssigned event
   *
   * @param event Sui event object
   * @returns Event data
   */
  private parseFreelancerAssignedEvent(event: SuiEvent): FreelancerAssignedEvent {
    return event.parsedJson as FreelancerAssignedEvent;
  }

  /**
   * Parse JobStateChanged event
   *
   * @param event Sui event object
   * @returns Event data
   */
  private parseJobStateChangedEvent(event: SuiEvent): JobStateChangedEvent {
    return event.parsedJson as JobStateChangedEvent;
  }
}

/**
 * Factory function to create JobEventIndexer instance
 *
 * @param suiClient Sui client instance
 * @param packageId Job escrow package ID
 * @returns JobEventIndexer instance
 */
export function createJobEventIndexer(
  suiClient: SuiClient,
  packageId: string
): JobEventIndexer {
  return new JobEventIndexer(suiClient, packageId);
}
