/// Profile NFT Module
/// Dynamic NFTs for freelancers and clients with reputation tracking
///
/// DEV 1 TODO:
/// 1. Implement profile minting with type enum
/// 2. Add dynamic field updates (job count, rating)
/// 3. Implement reputation calculation logic
/// 4. Add profile metadata management
/// 5. Test profile updates and queries
/// 6. Consider adding profile verification system

module zk_freelance::profile_nft {
    use std::string::{Self, String};
    use sui::event;
    use sui::clock::{Self, Clock};
    use sui::vec_set::{Self, VecSet};

    // ======== Constants ========

    /// Profile types
    const PROFILE_TYPE_FREELANCER: u8 = 0;
    const PROFILE_TYPE_CLIENT: u8 = 1;

    /// Error codes
    const EInvalidProfileType: u64 = 0;
    const ENotProfileOwner: u64 = 1;
    const EProfileAlreadyExists: u64 = 2;
    const EInvalidRating: u64 = 3;
    const EInvalidUpdate: u64 = 4;

    // ======== Structs ========

    /// Profile NFT - owned by user
    public struct Profile has key, store {
        id: UID,
        /// Owner address
        owner: address,
        /// Profile type (Freelancer or Client)
        profile_type: u8,
        /// Username (display name)
        username: String,
        /// Real name (optional, can be empty)
        real_name: String,
        /// Bio / description
        bio: String,
        /// Skills (for freelancers) or Industry (for clients)
        tags: vector<String>,
        /// Profile picture URL (could be Walrus blob ID)
        avatar_url: String,
        /// Creation timestamp
        created_at: u64,
        /// Last updated timestamp
        updated_at: u64,
        /// Completed jobs count
        completed_jobs: u64,
        /// Jobs posted (for clients) or applied to (for freelancers)
        total_jobs: u64,
        /// Average rating (scaled by 100, e.g., 450 = 4.50 stars)
        rating: u64,
        /// Number of ratings received
        rating_count: u64,
        /// Total amount earned (freelancers) or spent (clients)
        total_amount: u64,
        /// Verification status
        verified: bool,
        /// Active job IDs
        active_jobs: VecSet<ID>,
    }

    /// Capability for profile owner to update profile
    public struct ProfileCap has key, store {
        id: UID,
        profile_id: ID,
    }

    // ======== Events ========

    public struct ProfileCreated has copy, drop {
        profile_id: ID,
        owner: address,
        profile_type: u8,
        username: String,
        timestamp: u64,
    }

    public struct ProfileUpdated has copy, drop {
        profile_id: ID,
        field: String,
        timestamp: u64,
    }

    public struct ReputationUpdated has copy, drop {
        profile_id: ID,
        new_rating: u64,
        rating_count: u64,
        timestamp: u64,
    }

    public struct JobCompleted has copy, drop {
        profile_id: ID,
        job_id: ID,
        amount: u64,
        timestamp: u64,
    }

    // ======== Public Functions ========

    /// Create a new profile
    ///
    /// TODO: Implement
    /// - Validate profile_type (0 or 1)
    /// - Create Profile NFT with initial values
    /// - Create ProfileCap linked to profile
    /// - Emit ProfileCreated event
    /// - Transfer Profile and ProfileCap to sender
    public fun create_profile(
        profile_type: u8,
        username: vector<u8>,
        real_name: vector<u8>,
        bio: vector<u8>,
        tags: vector<vector<u8>>,
        avatar_url: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // TODO: Implement
        abort EInvalidProfileType
    }

    /// Update profile information (owner only)
    ///
    /// TODO: Implement
    /// - Verify ProfileCap ownership and linkage
    /// - Update allowed fields (username, bio, tags, avatar_url, real_name)
    /// - Update updated_at timestamp
    /// - Emit ProfileUpdated event
    public fun update_profile_info(
        profile: &mut Profile,
        cap: &ProfileCap,
        username: Option<vector<u8>>,
        real_name: Option<vector<u8>>,
        bio: Option<vector<u8>>,
        tags: Option<vector<vector<u8>>>,
        avatar_url: Option<vector<u8>>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // TODO: Implement
        abort ENotProfileOwner
    }

    /// Add rating to profile (called by job_escrow module)
    ///
    /// TODO: Implement
    /// - Validate rating (1-500, representing 0.1 to 5.0 stars)
    /// - Calculate new average rating
    /// - Increment rating_count
    /// - Update updated_at
    /// - Emit ReputationUpdated event
    public fun add_rating(
        profile: &mut Profile,
        rating: u64,
        clock: &Clock,
    ) {
        // TODO: Implement
        // New average = (old_average * old_count + new_rating) / (old_count + 1)
        abort EInvalidRating
    }

    /// Record job completion (called by job_escrow module)
    ///
    /// TODO: Implement
    /// - Increment completed_jobs
    /// - Add amount to total_amount
    /// - Remove job from active_jobs if present
    /// - Update updated_at
    /// - Emit JobCompleted event
    public fun record_job_completion(
        profile: &mut Profile,
        job_id: ID,
        amount: u64,
        clock: &Clock,
    ) {
        // TODO: Implement
        abort EInvalidUpdate
    }

    /// Add job to active jobs (called when job assigned/created)
    ///
    /// TODO: Implement
    /// - Add job_id to active_jobs VecSet
    /// - Increment total_jobs
    /// - Update updated_at
    public fun add_active_job(
        profile: &mut Profile,
        job_id: ID,
        clock: &Clock,
    ) {
        // TODO: Implement
        abort EInvalidUpdate
    }

    /// Remove job from active jobs (called when job completed/cancelled)
    ///
    /// TODO: Implement
    /// - Remove job_id from active_jobs VecSet
    /// - Update updated_at
    public fun remove_active_job(
        profile: &mut Profile,
        job_id: ID,
        clock: &Clock,
    ) {
        // TODO: Implement
        abort EInvalidUpdate
    }

    /// Set verification status (admin only - implement permission check)
    ///
    /// TODO: Implement
    /// - Add admin capability check
    /// - Set verified status
    /// - Emit event
    public fun set_verification(
        profile: &mut Profile,
        verified: bool,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // TODO: Implement with admin permission
        abort ENotProfileOwner
    }

    // ======== Getter Functions ========

    /// Get profile owner
    public fun get_owner(profile: &Profile): address {
        profile.owner
    }

    /// Get profile type
    public fun get_profile_type(profile: &Profile): u8 {
        profile.profile_type
    }

    /// Get username
    public fun get_username(profile: &Profile): String {
        profile.username
    }

    /// Get bio
    public fun get_bio(profile: &Profile): String {
        profile.bio
    }

    /// Get rating (scaled by 100)
    public fun get_rating(profile: &Profile): u64 {
        profile.rating
    }

    /// Get rating count
    public fun get_rating_count(profile: &Profile): u64 {
        profile.rating_count
    }

    /// Get completed jobs count
    public fun get_completed_jobs(profile: &Profile): u64 {
        profile.completed_jobs
    }

    /// Get total jobs
    public fun get_total_jobs(profile: &Profile): u64 {
        profile.total_jobs
    }

    /// Get total amount
    public fun get_total_amount(profile: &Profile): u64 {
        profile.total_amount
    }

    /// Check if verified
    public fun is_verified(profile: &Profile): bool {
        profile.verified
    }

    /// Get active jobs count
    public fun get_active_jobs_count(profile: &Profile): u64 {
        vec_set::size(&profile.active_jobs)
    }

    /// Check if job is active
    public fun is_job_active(profile: &Profile, job_id: ID): bool {
        vec_set::contains(&profile.active_jobs, &job_id)
    }

    /// Get ProfileCap's linked profile ID
    public fun get_cap_profile_id(cap: &ProfileCap): ID {
        cap.profile_id
    }

    // ======== Helper Functions ========

    /// Verify ProfileCap matches Profile
    fun verify_cap(profile: &Profile, cap: &ProfileCap) {
        assert!(object::id(profile) == cap.profile_id, ENotProfileOwner);
    }

    /// Calculate new average rating
    fun calculate_new_rating(old_rating: u64, old_count: u64, new_rating: u64): u64 {
        // TODO: Implement
        // (old_rating * old_count + new_rating) / (old_count + 1)
        0
    }

    /// Validate rating value (10-500, representing 0.1-5.0 stars)
    fun is_valid_rating(rating: u64): bool {
        rating >= 10 && rating <= 500
    }

    // ======== Test Functions ========

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        // Test initialization if needed
    }

    #[test_only]
    public fun create_test_profile(
        profile_type: u8,
        ctx: &mut TxContext
    ): Profile {
        // TODO: Create test profile
        abort EInvalidProfileType
    }
}
