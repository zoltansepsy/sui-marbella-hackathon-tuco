# Job Assignment Ownership Fix - Implementation Summary

## Problem

The `assign_freelancer` function in `job_escrow.move` failed at runtime because it required the **client** to pass the **freelancer's Profile** object. On Sui, only the owner of an object can pass it in a transaction - the client doesn't own the freelancer's profile, causing `InvalidOwner` or `MutableObjectUsedAsImmutable` errors.

## Solution

Moved the profile update logic from `assign_freelancer` (client action) to `start_job` (freelancer action):

| Function | Before | After |
|----------|--------|-------|
| `assign_freelancer` | Required `freelancer_profile` param | No profile param needed |
| `start_job` | No profile param | Now requires `freelancer_profile` param |

The freelancer now provides their own profile when they call `start_job`, which they can do because they own it.

## Files Changed

### Smart Contract (`move/zk_freelance/sources/job_escrow.move`)

**`assign_freelancer` (lines 313-352):**
```move
// BEFORE: 6 parameters including freelancer_profile
public fun assign_freelancer(
    job: &mut Job,
    cap: &JobCap,
    freelancer: address,
    freelancer_profile: &mut Profile,  // REMOVED
    clock: &Clock,
    ctx: &mut TxContext
)

// AFTER: 5 parameters, no profile needed
public fun assign_freelancer(
    job: &mut Job,
    cap: &JobCap,
    freelancer: address,
    clock: &Clock,
    ctx: &mut TxContext
)
```

**`start_job` (lines 358-401):**
```move
// BEFORE: 3 parameters
public fun start_job(
    job: &mut Job,
    clock: &Clock,
    ctx: &mut TxContext
)

// AFTER: 4 parameters, includes freelancer_profile + profile updates
public fun start_job(
    job: &mut Job,
    freelancer_profile: &mut Profile,  // ADDED
    clock: &Clock,
    ctx: &mut TxContext
) {
    // ... validation ...

    // Verify profile ownership
    let freelancer = *option::borrow(&job.freelancer);
    assert!(profile_nft::get_owner(freelancer_profile) == freelancer, ENotAuthorized);

    // Get the stored cap and increment total_jobs
    let job_profile_cap = table::borrow(&job.applicant_caps, freelancer);
    profile_nft::increment_total_jobs(freelancer_profile, job_profile_cap, clock);

    // Add job to freelancer's active jobs
    profile_nft::add_active_job(freelancer_profile, object::id(job), clock);

    // ... state transition and events ...
}
```

### Tests

**`job_workflow_state_machine_tests.move`:**
- Updated `apply_and_assign` helper - removed freelancer_profile from assign
- Updated `start_job` helper - added freelancer_profile handling
- Fixed `test_concurrent_applications` - removed profile from assign call
- Updated assertions: `total_jobs` is now 0 after assign, 1 after start_job

**`job_escrow_tests.move`:**
- Updated ~20 occurrences of `assign_freelancer` calls
- Updated ~19 occurrences of `start_job` calls
- Added proper profile take/return patterns in each transaction block

### TypeScript Service (`app/services/jobService.ts`)

```typescript
// BEFORE
assignFreelancerTransaction(
  jobId: string,
  jobCapId: string,
  freelancerAddress: string,
  freelancerProfileId: string  // REMOVED
): Transaction

// AFTER
assignFreelancerTransaction(
  jobId: string,
  jobCapId: string,
  freelancerAddress: string
): Transaction

// BEFORE
startJobTransaction(jobId: string): Transaction

// AFTER
startJobTransaction(jobId: string, freelancerProfileId: string): Transaction
```

### Frontend (`app/components/job/ClientJobDetailView.tsx`)

Removed the freelancer profile lookup from `handleAssignFreelancer`:
```typescript
// No longer need freelancer profile - profile update now happens in start_job
const tx = jobService.assignFreelancerTransaction(
  jobId,
  jobCapId,
  freelancerAddress
  // freelancerProfileId removed
);
```

### Shell Test Script (`test_job_workflow_devnet.sh`)

- Updated from 7 steps to 8 steps
- Step 7: `assign_freelancer` now succeeds (no profile needed)
- Step 8: Added `start_job` as freelancer with profile

## Test Results

All **98 Move tests pass** after the changes.

## Job Workflow After Fix

```
1. Client creates job (OPEN)
2. Freelancer applies with JobProfileUpdateCap
3. Client assigns freelancer (ASSIGNED) - no profile needed
4. Freelancer starts job (IN_PROGRESS) - provides own profile, total_jobs incremented
5. Freelancer submits milestone (SUBMITTED)
6. Client approves milestone (COMPLETED)
```
