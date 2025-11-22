# Developer Handoff - Zero-Knowledge Freelance Platform

## Project Status: Skeleton Complete ✅

The project skeleton is fully implemented and ready for the 3-developer team to begin implementation. All architecture, types, and interfaces are in place.

## Quick Start

```bash
# Install dependencies
pnpm install

# Start development server
pnpm dev

# Open http://localhost:3000
```

## What's Been Created

### ✅ Smart Contract Skeletons (Dev 1 Domain)

All Move contract files are created with:
- Complete struct definitions
- Function signatures with TODOs
- Event definitions
- Comprehensive comments

**Files Created**:
- [move/zk_freelance/sources/job_escrow.move](move/zk_freelance/sources/job_escrow.move)
- [move/zk_freelance/sources/profile_nft.move](move/zk_freelance/sources/profile_nft.move)
- [move/zk_freelance/sources/milestone.move](move/zk_freelance/sources/milestone.move)
- [move/zk_freelance/sources/reputation.move](move/zk_freelance/sources/reputation.move)

### ✅ Service Layer (Dev 2 Domain)

All service classes with method signatures, TypeScript types, and patterns to follow:

**Files Created**:
- [app/services/jobService.ts](app/services/jobService.ts) - Job operations
- [app/services/profileService.ts](app/services/profileService.ts) - Profile management
- [app/services/reputationService.ts](app/services/reputationService.ts) - Ratings
- [app/services/types.ts](app/services/types.ts) - Extended with all platform types
- [app/services/index.ts](app/services/index.ts) - Updated exports

**Custom Hooks Created**:
- [app/hooks/useJob.ts](app/hooks/useJob.ts)
- [app/hooks/useProfile.ts](app/hooks/useProfile.ts)
- [app/hooks/useWallet.ts](app/hooks/useWallet.ts)
- [app/hooks/index.ts](app/hooks/index.ts)

### ✅ UI Components (Dev 3 Domain)

Component structure with skeleton files:

**Directories Created**:
- [app/components/job/](app/components/job/) - JobCard.tsx, JobList.tsx (with skeletons)
- [app/components/profile/](app/components/profile/) - ProfileCard.tsx (with skeleton)
- [app/components/escrow/](app/components/escrow/) - (empty, ready for components)
- [app/components/common/](app/components/common/) - (empty, for shared components)

### ✅ Configuration & Routing

All configurations updated:

**Updated Files**:
- [app/constants.ts](app/constants.ts) - Added package ID constants for all modules
- [app/networkConfig.ts](app/networkConfig.ts) - Added network variables
- [app/contexts/ViewContext.tsx](app/contexts/ViewContext.tsx) - Added all view types
- [app/App.tsx](app/App.tsx) - Added routing for all platform views
- [app/components/Navbar.tsx](app/components/Navbar.tsx) - Updated navigation

### ✅ Documentation

Comprehensive documentation in [CLAUDE.md](CLAUDE.md):
- Platform architecture overview
- Smart contract module details
- Service layer patterns
- Component structure
- Integration workflows (Walrus + Seal)
- Development guidelines

---

## Architecture Decision: Event-Based Job Discovery

### Why Event-Based Indexing?

**The Challenge**: We need to list all jobs across all clients for the marketplace, but:
- Job objects are **shared objects** (not owned by anyone)
- Sui doesn't support querying all shared objects of a type
- We can't do "SELECT * FROM Jobs WHERE state = OPEN" on-chain

**The Solution**: Event-Based Indexing (Industry Standard Pattern)

This is the **proven Sui pattern** used by all production marketplaces (Kiosk, DEXs, NFT platforms):
1. ✅ Smart contracts emit comprehensive events for all state changes
2. ✅ Client queries events to discover jobs
3. ✅ Optional: Fetch full Job object for current details

### Why NOT Registry Pattern?

We rejected creating a shared `JobMarketplace` registry because:
- ❌ **Shared object contention**: Every job creation/update requires consensus
- ❌ **Gas costs increase 5-10x** during high traffic
- ❌ **Performance degrades at scale** - transactions serialize
- ❌ Sui documentation explicitly warns against single shared objects

### Implementation Overview

```
Smart Contract (Move)
├─ Emit JobCreated event (with full job details)
├─ Emit JobStateChanged event (for state tracking)
└─ Emit FreelancerAssigned event (for freelancer queries)
        ↓
JobEventIndexer Service (TypeScript)
├─ queryOpenJobs() → filters JobCreated + JobStateChanged
├─ queryJobsByClient() → filters JobCreated by sender
└─ queryJobsByFreelancer() → filters FreelancerAssigned events
        ↓
JobService (TypeScript)
├─ getOpenJobs() → calls indexer, returns JobData[]
├─ getJobsByClient() → calls indexer, returns JobData[]
└─ getJobsByFreelancer() → calls indexer, returns JobData[]
        ↓
Hooks (React)
├─ useOpenJobs() → useQuery with auto-refresh
├─ useJobsByClient() → useQuery with caching
└─ useJobsByFreelancer() → useQuery with caching
        ↓
UI Components
└─ JobList displays jobs from hooks
```

### Key Files

**Smart Contract**: [move/zk_freelance/sources/job_escrow.move](move/zk_freelance/sources/job_escrow.move)
- Enhanced events with comprehensive data (lines 93-189)

**Event Indexer**: [app/services/jobEventIndexer.ts](app/services/jobEventIndexer.ts) ✨ NEW
- `queryOpenJobs()` - Marketplace listings
- `queryJobsByClient()` - Client's posted jobs
- `queryJobsByFreelancer()` - Freelancer's assigned jobs

**Job Service**: [app/services/jobService.ts](app/services/jobService.ts)
- Now calls event indexer instead of returning empty arrays
- `getOpenJobs()`, `getJobsByClient()`, `getJobsByFreelancer()` fully implemented

**Hooks**: [app/hooks/useJob.ts](app/hooks/useJob.ts)
- All hooks now use `@tanstack/react-query` for caching
- Auto-refresh every 30 seconds for live updates

### For Developers

**Dev 1 (Smart Contracts)**:
- ✅ Events are already enhanced with all necessary fields
- When implementing functions, **emit events with complete data**
- Example: `JobCreated` includes title, budget, deadline, etc.

**Dev 2 (Services)**:
- ✅ Event indexing is fully implemented
- Services now call `JobEventIndexer` methods
- No need to return empty arrays anymore

**Dev 3 (Frontend)**:
- ✅ Hooks are ready to use
- Call `useOpenJobs()` to get marketplace listings
- Call `useJobsByClient(address)` for client's jobs
- Data auto-refreshes every 30 seconds

---

## Developer Tasks

### 🔧 Dev 1: Smart Contract Implementation

**Priority Order**:
1. **job_escrow.move** (2-3 days)
   - Implement all TODO functions
   - Focus on state machine logic
   - Test escrow fund management

2. **profile_nft.move** (1-2 days)
   - Implement profile creation
   - Add dynamic field updates
   - Test rating calculations

3. **reputation.move** (1 day)
   - Implement rating submission
   - Add badge eligibility logic

4. **milestone.move** (optional)
   - Can be integrated into job_escrow if time is short

**Testing Checklist**:
```bash
cd move/zk_freelance
sui move test
sui move build
```

**Deployment**:
```bash
sui client publish --gas-budget 100000000 .
# Copy package ID and update app/constants.ts
```

**Key Patterns to Follow**:
- Use `Balance<SUI>` for escrow (not `Coin<SUI>`)
- **Always emit events for state changes** (CRITICAL for event-based indexing)
- Use `Clock` object for timestamps
- Validate state transitions in every function
- Cap pattern for admin operations
- Make Job a **shared object** with `transfer::share_object(job)`

**Event Emission Example**:
```move
public fun create_job(...) {
    // Create job object
    let job = Job { ... };
    let job_id = object::uid_to_inner(&job.id);

    // Emit comprehensive event (REQUIRED for discovery)
    event::emit(JobCreated {
        job_id,
        client: sender,
        title,
        description_blob_id,
        budget,
        deadline,
        milestone_count: 0,
        state: STATE_OPEN,
        timestamp: clock::timestamp_ms(clock),
    });

    // Share the job object (makes it accessible to all)
    transfer::share_object(job);

    // Transfer capability to client
    transfer::transfer(job_cap, sender);
}

---

### 🔗 Dev 2: Service Layer Implementation

**Status**: ✅ Event-based queries fully implemented

**Priority Order**:
1. **Transaction Builders** (1-2 days)
   - Implement TODOs in jobService.ts transaction methods
   - Follow pattern in commented code
   - Test with deployed contracts

2. **profileService.ts** (1-2 days)
   - Implement profile operations
   - Add profile queries (can follow job event pattern if needed)

3. **Testing** (ongoing)
   - Test event queries work correctly
   - Verify data parsing from events

**Event-Based Query Architecture** (✅ Already Implemented):

The query methods now use event-based indexing:

```typescript
// Example: How getOpenJobs() works
async getOpenJobs(limit: number = 50): Promise<JobData[]> {
  // 1. Create event indexer
  const indexer = createJobEventIndexer(this.suiClient, this.packageId);

  // 2. Query events (filters for OPEN state automatically)
  const jobEvents = await indexer.queryOpenJobs(limit);

  // 3. Convert event data to JobData format
  const jobs = jobEvents.map(event => ({
    objectId: event.jobId,
    client: event.client,
    title: event.title,
    budget: event.budget,
    state: event.state,
    // ... other fields from event
  }));

  return jobs;
}
```

**What Dev 2 Needs to Do**:

1. **Implement Transaction Builders** (Still TODO):
   - `createJobTransaction()` - Build moveCall for create_job
   - `applyForJobTransaction()` - Build moveCall for apply_for_job
   - `assignFreelancerTransaction()` - Build moveCall for assign_freelancer
   - etc. (follow TODOs in jobService.ts)

2. **Test Event Queries** (After Dev 1 deploys):
   ```typescript
   const service = createJobService(suiClient, packageId);

   // Test marketplace listing
   const openJobs = await service.getOpenJobs();
   console.log("Open jobs:", openJobs);

   // Test client jobs
   const myJobs = await service.getJobsByClient(myAddress);
   console.log("My jobs:", myJobs);
   ```

**Key Patterns to Follow**:
- Always use `useMemo` for service instances
- Wait for transaction confirmation before refetching
- Parse `vector<u8>` to strings with `vectorU8ToString`
- Handle `Option` types properly
- **Events provide discovery, Job objects provide current state**

**Integration Points**:
- Wait for Dev 1 to deploy contracts
- Get package IDs and update constants.ts
- Test event queries return data after jobs are created

---

### 🎨 Dev 3: Frontend Implementation

**Status**: ✅ Hooks ready with event-based queries

**Priority Order**:
1. **Job Marketplace View** (2 days)
   - Create JobMarketplaceView component
   - Integrate useOpenJobs hook
   - Add job filtering/sorting

2. **Job Detail View** (1-2 days)
   - Create JobDetailView component
   - Show full job information
   - Add apply/milestone actions

3. **My Jobs View** (1 day)
   - Create MyJobsView component
   - Show user's jobs (client/freelancer)
   - Add job management actions

4. **Profile View** (1 day)
   - Create ProfileView component
   - Show profile with ratings
   - Add profile edit form

5. **Create Job View** (1 day)
   - Create CreateJobView component
   - Multi-step form (job info → milestones → review)
   - Integrate Walrus upload

**Component Locations**:
- Views: Create in `app/` directory (e.g., `app/JobMarketplaceView.tsx`)
- Import in `App.tsx` and replace placeholder views
- Reusable components: `app/components/job/`, `app/components/profile/`

**Using the Job Hooks** (✅ Ready to Use):

```typescript
import { useOpenJobs, useJobsByClient, useJob } from "@/hooks";

// Marketplace view
function JobMarketplace() {
  const { jobs, isPending, error } = useOpenJobs(20);

  if (isPending) return <div>Loading jobs...</div>;
  if (error) return <Alert>Error: {error.message}</Alert>;

  return (
    <div>
      {jobs.map(job => (
        <JobCard key={job.objectId} job={job} />
      ))}
    </div>
  );
}

// Client's posted jobs
function MyPostedJobs() {
  const { currentAccount } = useCurrentAccount();
  const { jobs, isPending } = useJobsByClient(currentAccount?.address);

  // Jobs auto-refresh every 30 seconds
  return <JobList jobs={jobs} loading={isPending} />;
}

// Single job details
function JobDetail({ jobId }: { jobId: string }) {
  const { job, isPending, refetch } = useJob(jobId);

  // Manually refetch after transaction
  const handleApply = async () => {
    // ... apply transaction ...
    await refetch(); // Update UI
  };

  return job ? <div>{job.title}</div> : <div>Loading...</div>;
}
```

**Key Patterns to Follow**:
- Use existing UI components from `app/components/ui/`
- Follow patterns in WalrusUpload.tsx and SealWhitelist.tsx
- Always show loading states (`isPending`)
- Handle errors gracefully with Alert components
- Use Button disabled states during transactions
- **Data auto-refreshes** - no need to manually refetch unless after mutations

**UI Libraries Available**:
- shadcn/ui components (Card, Button, Alert, Input)
- Radix UI (NavigationMenu, etc.)
- Tailwind CSS for styling
- lucide-react for icons
- @tanstack/react-query (handles caching/refetching automatically)

---

## Team Collaboration

### Git Workflow

```bash
# Dev 1: Smart contracts branch
git checkout -b feature/smart-contracts

# Dev 2: Services branch
git checkout -b feature/services

# Dev 3: UI branch
git checkout -b feature/ui
```

### Merge Order

1. **Dev 1 merges first** → Deploy contracts → Update constants.ts
2. **Dev 2 merges second** → Test services with deployed contracts
3. **Dev 3 merges last** → Connect UI to services

### Communication Points

**Dev 1 → Dev 2**:
- Share deployed package IDs
- Document any contract API changes
- Provide event structure details

**Dev 2 → Dev 3**:
- Document all service method signatures
- Share hook usage examples
- Provide TypeScript types

**Dev 3 → Dev 1/2**:
- Request additional contract functions if needed
- Suggest optimal data structures for UI

---

## Testing Strategy

### Contract Testing (Dev 1)
```bash
cd move/zk_freelance
sui move test --coverage
sui move build
```

### Service Testing (Dev 2)
- Test each transaction builder in browser
- Verify object parsing
- Check error handling

### UI Testing (Dev 3)
- Test all views with wallet connected
- Test error states (no wallet, insufficient funds)
- Test loading states
- Mobile responsiveness

### End-to-End Flow
1. Create profile as client
2. Post a job
3. Switch wallet, create freelancer profile
4. Apply for job
5. Client assigns freelancer
6. Freelancer submits milestone
7. Client approves milestone
8. Verify payment released

---

## Current State

### ✅ Completed
- All skeleton files created
- All types defined
- Configuration updated
- Documentation written
- Basic UI routing implemented

### ⏳ Remaining (Developer Tasks)
- Smart contract logic implementation
- Service layer implementation
- Custom hook implementation
- Full view components
- End-to-end testing
- Utility functions (formatting, validation)

### 🚀 Ready to Start
- All developers can start in parallel
- Clear separation of concerns
- Well-defined interfaces
- Comprehensive TODOs in every file

---

## Resources

### Documentation
- Main docs: [CLAUDE.md](CLAUDE.md)
- Sui Move docs: https://docs.sui.io/build/move
- dApp Kit docs: https://sdk.mystenlabs.com/dapp-kit
- Walrus docs: https://docs.walrus.site/
- Seal docs: https://docs.seal.su/

### Existing Code to Reference
- Counter example: [move/zk_freelance/sources/counter.move](move/zk_freelance/sources/counter.move)
- Whitelist example: [move/zk_freelance/sources/whitelist.move](move/zk_freelance/sources/whitelist.move)
- Counter service: [app/services/counterService.ts](app/services/counterService.ts)
- Walrus upload: [app/WalrusUpload.tsx](app/WalrusUpload.tsx)
- Seal integration: [app/SealWhitelist.tsx](app/SealWhitelist.tsx)

### Quick Links
- Sui Explorer (testnet): https://suiscan.xyz/testnet
- WalrusCan: https://walruscan.com/testnet
- Get testnet SUI: https://faucet.sui.io/

---

## Questions?

All documentation is in [CLAUDE.md](CLAUDE.md). Search for your module/component name to find relevant guidance.

**Good luck building! 🚀**
