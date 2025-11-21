/// Job Escrow Module
/// Manages job posting, freelancer assignment, milestone tracking, and payment escrow
///
/// DEV 1 TODO:
/// 1. Implement complete state machine transitions
/// 2. Add deadline enforcement logic
/// 3. Implement refund mechanism
/// 4. Add applicant management
/// 5. Test all state transitions
/// 6. Add comprehensive error codes

module zk_freelance::job_escrow {
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use sui::table::{Self, Table};
    use sui::event;
    use sui::clock::{Self, Clock};

    // ======== Constants ========

    /// Job states
    const STATE_OPEN: u8 = 0;
    const STATE_ASSIGNED: u8 = 1;
    const STATE_IN_PROGRESS: u8 = 2;
    const STATE_SUBMITTED: u8 = 3;
    const STATE_AWAITING_REVIEW: u8 = 4;
    const STATE_COMPLETED: u8 = 5;
    const STATE_CANCELLED: u8 = 6;
    const STATE_DISPUTED: u8 = 7;

    /// Error codes
    const ENotAuthorized: u64 = 0;
    const EInvalidState: u64 = 1;
    const EInsufficientFunds: u64 = 2;
    const EDeadlinePassed: u64 = 3;
    const EInvalidMilestone: u64 = 4;
    const EJobNotOpen: u64 = 5;
    const EAlreadyApplied: u64 = 6;
    const EFreelancerNotAssigned: u64 = 7;

    // ======== Structs ========

    /// Main Job object - shared object
    public struct Job has key {
        id: UID,
        /// Client who posted the job
        client: address,
        /// Assigned freelancer (Option)
        freelancer: Option<address>,
        /// Job title
        title: vector<u8>,
        /// Description stored on Walrus (blob ID)
        description_blob_id: vector<u8>,
        /// Total budget in MIST
        budget: u64,
        /// Escrow holding the funds
        escrow: Balance<SUI>,
        /// Current state
        state: u8,
        /// Milestones table
        milestones: Table<u64, Milestone>,
        /// Number of milestones
        milestone_count: u64,
        /// List of applicants
        applicants: vector<address>,
        /// Job creation timestamp
        created_at: u64,
        /// Job deadline timestamp
        deadline: u64,
        /// Deliverable blob IDs (encrypted with Seal)
        deliverable_blob_ids: vector<vector<u8>>,
    }

    /// Milestone struct
    public struct Milestone has store {
        id: u64,
        description: vector<u8>,
        amount: u64,
        completed: bool,
        approved: bool,
        submission_blob_id: Option<vector<u8>>,
        submitted_at: Option<u64>,
        approved_at: Option<u64>,
    }

    /// Job capability - given to client for management
    public struct JobCap has key, store {
        id: UID,
        job_id: ID,
    }

    // ======== Events ========

    public struct JobCreated has copy, drop {
        job_id: ID,
        client: address,
        budget: u64,
        deadline: u64,
        timestamp: u64,
    }

    public struct FreelancerApplied has copy, drop {
        job_id: ID,
        freelancer: address,
        timestamp: u64,
    }

    public struct FreelancerAssigned has copy, drop {
        job_id: ID,
        freelancer: address,
        timestamp: u64,
    }

    public struct JobStarted has copy, drop {
        job_id: ID,
        timestamp: u64,
    }

    public struct MilestoneSubmitted has copy, drop {
        job_id: ID,
        milestone_id: u64,
        freelancer: address,
        timestamp: u64,
    }

    public struct MilestoneApproved has copy, drop {
        job_id: ID,
        milestone_id: u64,
        amount: u64,
        timestamp: u64,
    }

    public struct JobCompleted has copy, drop {
        job_id: ID,
        total_paid: u64,
        timestamp: u64,
    }

    public struct JobCancelled has copy, drop {
        job_id: ID,
        refund_amount: u64,
        timestamp: u64,
    }

    public struct FundsReleased has copy, drop {
        job_id: ID,
        recipient: address,
        amount: u64,
        timestamp: u64,
    }

    // ======== Public Functions ========

    /// Create a new job with escrow funding
    /// Returns JobCap to the client
    ///
    /// TODO: Implement full logic
    /// - Validate budget > 0
    /// - Create Job object with escrow
    /// - Create JobCap linked to job
    /// - Emit JobCreated event
    /// - Share Job object
    /// - Transfer JobCap to client
    public fun create_job(
        title: vector<u8>,
        description_blob_id: vector<u8>,
        budget: Coin<SUI>,
        deadline: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // TODO: Implement
        abort ENotAuthorized
    }

    /// Apply for a job as freelancer
    ///
    /// TODO: Implement
    /// - Check job state is OPEN
    /// - Check not already applied
    /// - Add sender to applicants list
    /// - Emit FreelancerApplied event
    public fun apply_for_job(
        job: &mut Job,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // TODO: Implement
        abort ENotAuthorized
    }

    /// Assign freelancer to job (client only)
    ///
    /// TODO: Implement
    /// - Verify JobCap ownership and linkage
    /// - Check job state is OPEN
    /// - Check freelancer is in applicants list
    /// - Set freelancer
    /// - Change state to ASSIGNED
    /// - Emit FreelancerAssigned event
    public fun assign_freelancer(
        job: &mut Job,
        cap: &JobCap,
        freelancer: address,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // TODO: Implement
        abort ENotAuthorized
    }

    /// Start work on job (freelancer only)
    ///
    /// TODO: Implement
    /// - Verify caller is assigned freelancer
    /// - Check state is ASSIGNED
    /// - Change state to IN_PROGRESS
    /// - Emit JobStarted event
    public fun start_job(
        job: &mut Job,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // TODO: Implement
        abort ENotAuthorized
    }

    /// Submit milestone completion (freelancer only)
    ///
    /// TODO: Implement
    /// - Verify caller is freelancer
    /// - Check milestone exists and not completed
    /// - Set submission_blob_id
    /// - Mark completed
    /// - Record timestamp
    /// - Change job state to SUBMITTED/AWAITING_REVIEW
    /// - Emit MilestoneSubmitted event
    public fun submit_milestone(
        job: &mut Job,
        milestone_id: u64,
        proof_blob_id: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // TODO: Implement
        abort ENotAuthorized
    }

    /// Approve milestone and release funds (client only)
    ///
    /// TODO: Implement
    /// - Verify JobCap ownership
    /// - Check milestone completed but not approved
    /// - Mark approved
    /// - Release funds from escrow to freelancer
    /// - Record timestamp
    /// - Check if all milestones approved → complete job
    /// - Emit MilestoneApproved event
    public fun approve_milestone(
        job: &mut Job,
        cap: &JobCap,
        milestone_id: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // TODO: Implement
        abort ENotAuthorized
    }

    /// Add milestone to job (client only, before assignment)
    ///
    /// TODO: Implement
    /// - Verify JobCap ownership
    /// - Check state is OPEN
    /// - Validate milestone amount
    /// - Add to milestones table
    /// - Increment milestone_count
    public fun add_milestone(
        job: &mut Job,
        cap: &JobCap,
        description: vector<u8>,
        amount: u64,
        ctx: &mut TxContext
    ) {
        // TODO: Implement
        abort ENotAuthorized
    }

    /// Cancel job and refund (client only, before IN_PROGRESS)
    ///
    /// TODO: Implement
    /// - Verify JobCap ownership
    /// - Check state allows cancellation (OPEN or ASSIGNED)
    /// - Refund escrow to client
    /// - Change state to CANCELLED
    /// - Emit JobCancelled event
    public fun cancel_job(
        job: &mut Job,
        cap: &JobCap,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // TODO: Implement
        abort ENotAuthorized
    }

    /// Complete job (internal, called when all milestones approved)
    ///
    /// TODO: Implement
    /// - Check all milestones approved
    /// - Change state to COMPLETED
    /// - Emit JobCompleted event
    fun complete_job(
        job: &mut Job,
        clock: &Clock,
    ) {
        // TODO: Implement
        abort ENotAuthorized
    }

    // ======== Getter Functions ========

    /// Get job state
    public fun get_state(job: &Job): u8 {
        job.state
    }

    /// Get job client
    public fun get_client(job: &Job): address {
        job.client
    }

    /// Get assigned freelancer
    public fun get_freelancer(job: &Job): Option<address> {
        job.freelancer
    }

    /// Get job budget
    public fun get_budget(job: &Job): u64 {
        job.budget
    }

    /// Get job deadline
    public fun get_deadline(job: &Job): u64 {
        job.deadline
    }

    /// Get milestone count
    public fun get_milestone_count(job: &Job): u64 {
        job.milestone_count
    }

    /// Check if address is in applicants
    public fun is_applicant(job: &Job, addr: address): bool {
        // TODO: Implement vector search
        false
    }

    /// Get JobCap's linked job ID
    public fun get_cap_job_id(cap: &JobCap): ID {
        cap.job_id
    }

    // ======== Helper Functions ========

    /// Verify JobCap matches Job
    fun verify_cap(job: &Job, cap: &JobCap) {
        assert!(object::id(job) == cap.job_id, ENotAuthorized);
    }

    /// Check if deadline has passed
    fun is_deadline_passed(job: &Job, clock: &Clock): bool {
        clock::timestamp_ms(clock) > job.deadline
    }

    /// Validate state transition
    fun can_transition(from: u8, to: u8): bool {
        // TODO: Implement state machine validation
        true
    }

    // ======== Test Functions ========

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        // Test initialization if needed
    }
}
