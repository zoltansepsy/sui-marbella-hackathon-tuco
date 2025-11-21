/// Milestone Module
/// Advanced milestone management with verification and dispute handling
///
/// DEV 1 TODO:
/// 1. Implement milestone verification with proof storage
/// 2. Add milestone revision request system
/// 3. Implement partial payment release
/// 4. Add milestone dispute handling
/// 5. Test integration with job_escrow
/// 6. Consider adding milestone templates

module zk_freelance::milestone {
    use sui::event;
    use sui::clock::{Self, Clock};
    use std::string::{Self, String};

    // ======== Constants ========

    /// Milestone states
    const STATE_PENDING: u8 = 0;
    const STATE_IN_PROGRESS: u8 = 1;
    const STATE_SUBMITTED: u8 = 2;
    const STATE_UNDER_REVIEW: u8 = 3;
    const STATE_APPROVED: u8 = 4;
    const STATE_REVISION_REQUESTED: u8 = 5;
    const STATE_DISPUTED: u8 = 6;

    /// Error codes
    const EInvalidState: u64 = 0;
    const ENotAuthorized: u64 = 1;
    const EInvalidMilestone: u64 = 2;
    const EInsufficientProof: u64 = 3;

    // ======== Structs ========

    /// Extended Milestone object (alternative to inline in job_escrow)
    /// This is optional - can keep milestones in job_escrow Table
    /// Provided as reference for potential standalone milestone system
    public struct MilestoneObject has key, store {
        id: UID,
        /// Parent job ID
        job_id: ID,
        /// Milestone number
        milestone_number: u64,
        /// Title/description
        title: String,
        /// Detailed description
        description: String,
        /// Amount in MIST
        amount: u64,
        /// Current state
        state: u8,
        /// Deliverable requirements (stored as vector of strings)
        requirements: vector<String>,
        /// Submission blob IDs (Walrus)
        submission_blob_ids: vector<vector<u8>>,
        /// Preview blob IDs (watermarked, for client review)
        preview_blob_ids: vector<vector<u8>>,
        /// Submission notes from freelancer
        submission_notes: String,
        /// Review notes from client
        review_notes: String,
        /// Revision request count
        revision_count: u64,
        /// Created timestamp
        created_at: u64,
        /// Submitted timestamp
        submitted_at: Option<u64>,
        /// Approved/Completed timestamp
        completed_at: Option<u64>,
    }

    // ======== Events ========

    public struct MilestoneCreated has copy, drop {
        milestone_id: ID,
        job_id: ID,
        amount: u64,
        timestamp: u64,
    }

    public struct MilestoneSubmitted has copy, drop {
        milestone_id: ID,
        submission_count: u64,
        timestamp: u64,
    }

    public struct MilestoneReviewed has copy, drop {
        milestone_id: ID,
        approved: bool,
        timestamp: u64,
    }

    public struct RevisionRequested has copy, drop {
        milestone_id: ID,
        revision_count: u64,
        notes: String,
        timestamp: u64,
    }

    // ======== Public Functions ========

    /// Create milestone object
    ///
    /// TODO: Implement
    /// - Create MilestoneObject with initial state PENDING
    /// - Link to job_id
    /// - Set amount and requirements
    /// - Emit MilestoneCreated event
    /// - Share or transfer object
    public fun create_milestone(
        job_id: ID,
        milestone_number: u64,
        title: vector<u8>,
        description: vector<u8>,
        amount: u64,
        requirements: vector<vector<u8>>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // TODO: Implement
        abort ENotAuthorized
    }

    /// Submit milestone with deliverables
    ///
    /// TODO: Implement
    /// - Verify caller is freelancer (via job_escrow check)
    /// - Check state allows submission
    /// - Add submission_blob_ids and preview_blob_ids
    /// - Set submission_notes
    /// - Change state to SUBMITTED
    /// - Record submitted_at
    /// - Emit MilestoneSubmitted event
    public fun submit_milestone(
        milestone: &mut MilestoneObject,
        submission_blob_ids: vector<vector<u8>>,
        preview_blob_ids: vector<vector<u8>>,
        notes: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // TODO: Implement
        abort ENotAuthorized
    }

    /// Request revision (client)
    ///
    /// TODO: Implement
    /// - Verify caller is client (via job_escrow check)
    /// - Check state is SUBMITTED or UNDER_REVIEW
    /// - Set review_notes
    /// - Increment revision_count
    /// - Change state to REVISION_REQUESTED
    /// - Emit RevisionRequested event
    public fun request_revision(
        milestone: &mut MilestoneObject,
        notes: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // TODO: Implement
        abort ENotAuthorized
    }

    /// Approve milestone (client)
    ///
    /// TODO: Implement
    /// - Verify caller is client
    /// - Check state is SUBMITTED or UNDER_REVIEW
    /// - Change state to APPROVED
    /// - Record completed_at
    /// - Emit MilestoneReviewed event
    /// - Trigger payment release in job_escrow
    public fun approve_milestone(
        milestone: &mut MilestoneObject,
        notes: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // TODO: Implement
        abort ENotAuthorized
    }

    // ======== Getter Functions ========

    /// Get milestone state
    public fun get_state(milestone: &MilestoneObject): u8 {
        milestone.state
    }

    /// Get amount
    public fun get_amount(milestone: &MilestoneObject): u64 {
        milestone.amount
    }

    /// Get job ID
    public fun get_job_id(milestone: &MilestoneObject): ID {
        milestone.job_id
    }

    /// Get revision count
    public fun get_revision_count(milestone: &MilestoneObject): u64 {
        milestone.revision_count
    }

    // ======== Helper Functions ========

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
