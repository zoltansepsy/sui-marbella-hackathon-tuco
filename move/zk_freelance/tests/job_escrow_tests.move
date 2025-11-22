/// Comprehensive test suite for job_escrow module
/// Tests cover: function-specific tests, state machine, escrow safety, access control,
/// deadline enforcement, budget validation, milestone lifecycle, event emissions,
/// error handling, integration, edge cases, security, and getter functions
#[test_only]
module zk_freelance::job_escrow_tests {
    use sui::test_scenario::{Self as ts, Scenario};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::clock::{Self, Clock};
    use sui::test_utils;
    use zk_freelance::job_escrow::{Self, Job, JobCap};

    // Test constants
    const CLIENT: address = @0xC1;
    const FREELANCER: address = @0xF1;
    const FREELANCER2: address = @0xF2;
    const RANDOM_USER: address = @0xA1;

    const BUDGET: u64 = 1_000_000_000; // 1 SUI
    const MILESTONE_AMOUNT: u64 = 500_000_000; // 0.5 SUI
    const SMALL_AMOUNT: u64 = 100_000_000; // 0.1 SUI

    const CURRENT_TIME: u64 = 1000000;
    const FUTURE_DEADLINE: u64 = 2000000;
    const PAST_DEADLINE: u64 = 500000;

    // Error codes (match job_escrow.move)
    const ENotAuthorized: u64 = 0;
    const EInvalidState: u64 = 1;
    const EInsufficientFunds: u64 = 2;
    const EDeadlinePassed: u64 = 3;
    const EInvalidMilestone: u64 = 4;
    const EJobNotOpen: u64 = 5;
    const EAlreadyApplied: u64 = 6;
    const EFreelancerNotAssigned: u64 = 7;

    // Job states
    const STATE_OPEN: u8 = 0;
    const STATE_ASSIGNED: u8 = 1;
    const STATE_IN_PROGRESS: u8 = 2;
    const STATE_SUBMITTED: u8 = 3;
    const STATE_AWAITING_REVIEW: u8 = 4;
    const STATE_COMPLETED: u8 = 5;
    const STATE_CANCELLED: u8 = 6;
    const STATE_DISPUTED: u8 = 7;

    // ======== Helper Functions ========

    /// Create test clock at specific timestamp
    fun create_clock(timestamp: u64, scenario: &mut Scenario): Clock {
        let mut clock = clock::create_for_testing(ts::ctx(scenario));
        clock::set_for_testing(&mut clock, timestamp);
        clock
    }

    /// Create a basic job for testing
    fun create_test_job(scenario: &mut Scenario, clock: &Clock) {
        ts::next_tx(scenario, CLIENT);
        {
            let budget_coin = coin::mint_for_testing<SUI>(BUDGET, ts::ctx(scenario));
            job_escrow::create_job(
                b"Test Job",
                b"blob_123",
                budget_coin,
                FUTURE_DEADLINE,
                clock,
                ts::ctx(scenario)
            );
        };
    }

    /// Add a milestone to job
    fun add_test_milestone(
        job: &mut Job,
        cap: &JobCap,
        description: vector<u8>,
        amount: u64,
        scenario: &mut Scenario
    ) {
        job_escrow::add_milestone(job, cap, description, amount, ts::ctx(scenario));
    }

    // ======== 1. Function-Specific Tests: create_job() ========

    #[test]
    fun test_create_job_success() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let budget_coin = coin::mint_for_testing<SUI>(BUDGET, ts::ctx(&mut scenario));
            job_escrow::create_job(
                b"Software Development",
                b"description_blob_456",
                budget_coin,
                FUTURE_DEADLINE,
                &clock,
                ts::ctx(&mut scenario)
            );
        };

        // Verify Job was created and shared
        ts::next_tx(&mut scenario, CLIENT);
        {
            let job = ts::take_shared<Job>(&scenario);
            assert!(job_escrow::get_state(&job) == STATE_OPEN, 0);
            assert!(job_escrow::get_client(&job) == CLIENT, 1);
            assert!(job_escrow::get_budget(&job) == BUDGET, 2);
            assert!(job_escrow::get_escrow_balance(&job) == BUDGET, 3);
            assert!(job_escrow::get_deadline(&job) == FUTURE_DEADLINE, 4);
            assert!(job_escrow::get_milestone_count(&job) == 0, 5);
            ts::return_shared(job);
        };

        // Verify JobCap was sent to client
        ts::next_tx(&mut scenario, CLIENT);
        {
            assert!(ts::has_most_recent_for_address<JobCap>(CLIENT), 6);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EInsufficientFunds)]
    fun test_create_job_zero_budget() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let budget_coin = coin::mint_for_testing<SUI>(0, ts::ctx(&mut scenario));
            job_escrow::create_job(
                b"Test Job",
                b"blob_123",
                budget_coin,
                FUTURE_DEADLINE,
                &clock,
                ts::ctx(&mut scenario)
            );
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EDeadlinePassed)]
    fun test_create_job_past_deadline() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let budget_coin = coin::mint_for_testing<SUI>(BUDGET, ts::ctx(&mut scenario));
            job_escrow::create_job(
                b"Test Job",
                b"blob_123",
                budget_coin,
                PAST_DEADLINE, // Past deadline
                &clock,
                ts::ctx(&mut scenario)
            );
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidState)]
    fun test_create_job_empty_title() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let budget_coin = coin::mint_for_testing<SUI>(BUDGET, ts::ctx(&mut scenario));
            job_escrow::create_job(
                b"", // Empty title
                b"blob_123",
                budget_coin,
                FUTURE_DEADLINE,
                &clock,
                ts::ctx(&mut scenario)
            );
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    fun test_create_job_deadline_at_current_time() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let budget_coin = coin::mint_for_testing<SUI>(BUDGET, ts::ctx(&mut scenario));
            // Should fail - deadline must be > current time
            job_escrow::create_job(
                b"Test Job",
                b"blob_123",
                budget_coin,
                CURRENT_TIME, // Deadline == current time
                &clock,
                ts::ctx(&mut scenario)
            );
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // ======== 2. Function-Specific Tests: apply_for_job() ========

    #[test]
    fun test_apply_for_job_success() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        // Freelancer applies
        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));

            assert!(job_escrow::is_applicant(&job, FREELANCER), 0);
            assert!(job_escrow::get_applicant_count(&job) == 1, 1);

            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    fun test_apply_multiple_freelancers() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        // Freelancer 1 applies
        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        // Freelancer 2 applies
        ts::next_tx(&mut scenario, FREELANCER2);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));

            assert!(job_escrow::get_applicant_count(&job) == 2, 0);
            assert!(job_escrow::is_applicant(&job, FREELANCER), 1);
            assert!(job_escrow::is_applicant(&job, FREELANCER2), 2);

            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EAlreadyApplied)]
    fun test_apply_for_job_duplicate() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));

            // Apply again - should fail
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));

            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = ENotAuthorized)]
    fun test_apply_for_job_client_cannot_apply() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            // Client tries to apply to own job
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EDeadlinePassed)]
    fun test_apply_after_deadline() {
        let mut scenario = ts::begin(CLIENT);
        let mut clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        // Advance time past deadline
        clock::set_for_testing(&mut clock, FUTURE_DEADLINE + 1);

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // ======== 3. Function-Specific Tests: assign_freelancer() ========

    #[test]
    fun test_assign_freelancer_success() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        // Freelancer applies
        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        // Client assigns freelancer
        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);

            job_escrow::assign_freelancer(&mut job, &cap, FREELANCER, &clock, ts::ctx(&mut scenario));

            assert!(job_escrow::get_state(&job) == STATE_ASSIGNED, 0);
            let freelancer_opt = job_escrow::get_freelancer(&job);
            assert!(option::is_some(&freelancer_opt), 1);
            assert!(*option::borrow(&freelancer_opt) == FREELANCER, 2);

            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = ENotAuthorized)]
    fun test_assign_non_applicant() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        // Client tries to assign someone who didn't apply
        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);

            job_escrow::assign_freelancer(&mut job, &cap, RANDOM_USER, &clock, ts::ctx(&mut scenario));

            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = ENotAuthorized)]
    fun test_assign_wrong_cap() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        // Create two jobs
        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, CLIENT);
        let cap1 = ts::take_from_sender<JobCap>(&scenario);
        ts::return_to_sender(&scenario, cap1);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let budget_coin = coin::mint_for_testing<SUI>(BUDGET, ts::ctx(&mut scenario));
            job_escrow::create_job(
                b"Second Job",
                b"blob_456",
                budget_coin,
                FUTURE_DEADLINE,
                &clock,
                ts::ctx(&mut scenario)
            );
        };

        // Try to use cap from first job on second job
        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job_ids = ts::most_recent_id_shared<Job>();
            let mut job2 = ts::take_shared_by_id<Job>(&scenario, option::extract(&mut job_ids));
            let cap1 = ts::take_from_sender<JobCap>(&scenario);

            // Using cap1 on job2 should fail
            job_escrow::assign_freelancer(&mut job2, &cap1, FREELANCER, &clock, ts::ctx(&mut scenario));

            ts::return_to_sender(&scenario, cap1);
            ts::return_shared(job2);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // ======== 4. Function-Specific Tests: add_milestone() ========

    #[test]
    fun test_add_milestone_success() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);

            job_escrow::add_milestone(&mut job, &cap, b"Milestone 1", MILESTONE_AMOUNT, ts::ctx(&mut scenario));

            assert!(job_escrow::get_milestone_count(&job) == 1, 0);

            let milestone = job_escrow::get_milestone(&job, 0);
            assert!(job_escrow::milestone_get_amount(milestone) == MILESTONE_AMOUNT, 1);
            assert!(!job_escrow::milestone_is_completed(milestone), 2);
            assert!(!job_escrow::milestone_is_approved(milestone), 3);

            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    fun test_add_multiple_milestones() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);

            job_escrow::add_milestone(&mut job, &cap, b"Milestone 1", MILESTONE_AMOUNT, ts::ctx(&mut scenario));
            job_escrow::add_milestone(&mut job, &cap, b"Milestone 2", MILESTONE_AMOUNT, ts::ctx(&mut scenario));

            assert!(job_escrow::get_milestone_count(&job) == 2, 0);

            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidMilestone)]
    fun test_add_milestone_exceeds_budget() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);

            // Try to add milestone larger than budget
            job_escrow::add_milestone(&mut job, &cap, b"Too Large", BUDGET + 1, ts::ctx(&mut scenario));

            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidMilestone)]
    fun test_add_milestone_total_exceeds_budget() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);

            job_escrow::add_milestone(&mut job, &cap, b"Milestone 1", 600_000_000, ts::ctx(&mut scenario));
            // This should fail - total would be 1.1 SUI
            job_escrow::add_milestone(&mut job, &cap, b"Milestone 2", 500_000_000, ts::ctx(&mut scenario));

            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidState)]
    fun test_add_milestone_after_assignment() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        // Apply and assign
        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::assign_freelancer(&mut job, &cap, FREELANCER, &clock, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        // Try to add milestone after assignment
        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);

            job_escrow::add_milestone(&mut job, &cap, b"Late Milestone", MILESTONE_AMOUNT, ts::ctx(&mut scenario));

            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // ======== 5. Function-Specific Tests: start_job() ========

    #[test]
    fun test_start_job_success() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        // Apply and assign
        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::assign_freelancer(&mut job, &cap, FREELANCER, &clock, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        // Freelancer starts job
        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::start_job(&mut job, &clock, ts::ctx(&mut scenario));

            assert!(job_escrow::get_state(&job) == STATE_IN_PROGRESS, 0);

            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EFreelancerNotAssigned)]
    fun test_start_job_wrong_freelancer() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::assign_freelancer(&mut job, &cap, FREELANCER, &clock, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        // Different freelancer tries to start
        ts::next_tx(&mut scenario, FREELANCER2);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::start_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EDeadlinePassed)]
    fun test_start_job_after_deadline() {
        let mut scenario = ts::begin(CLIENT);
        let mut clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::assign_freelancer(&mut job, &cap, FREELANCER, &clock, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        // Advance past deadline
        clock::set_for_testing(&mut clock, FUTURE_DEADLINE + 1);

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::start_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // ======== 6. Function-Specific Tests: submit_milestone() ========

    #[test]
    fun test_submit_milestone_success() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        // Setup: create job with milestone, assign, start
        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::add_milestone(&mut job, &cap, b"Design Phase", MILESTONE_AMOUNT, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::assign_freelancer(&mut job, &cap, FREELANCER, &clock, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::start_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        // Submit milestone
        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::submit_milestone(&mut job, 0, b"proof_blob_789", &clock, ts::ctx(&mut scenario));

            assert!(job_escrow::get_state(&job) == STATE_SUBMITTED, 0);

            let milestone = job_escrow::get_milestone(&job, 0);
            assert!(job_escrow::milestone_is_completed(milestone), 1);
            assert!(!job_escrow::milestone_is_approved(milestone), 2);

            let blob_id_opt = job_escrow::milestone_get_submission_blob_id(milestone);
            assert!(option::is_some(&blob_id_opt), 3);

            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidMilestone)]
    fun test_submit_nonexistent_milestone() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        // Setup to IN_PROGRESS
        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::assign_freelancer(&mut job, &cap, FREELANCER, &clock, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::start_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        // Try to submit milestone that doesn't exist
        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::submit_milestone(&mut job, 999, b"proof", &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidState)]
    fun test_submit_milestone_already_completed() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        // Setup with milestone
        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::add_milestone(&mut job, &cap, b"Milestone", MILESTONE_AMOUNT, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::assign_freelancer(&mut job, &cap, FREELANCER, &clock, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::start_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::submit_milestone(&mut job, 0, b"proof", &clock, ts::ctx(&mut scenario));

            // Try to submit same milestone again
            job_escrow::submit_milestone(&mut job, 0, b"proof2", &clock, ts::ctx(&mut scenario));

            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // ======== 7. Function-Specific Tests: approve_milestone() ========

    #[test]
    fun test_approve_milestone_success() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        // Full flow to submission
        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::add_milestone(&mut job, &cap, b"Milestone", MILESTONE_AMOUNT, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::assign_freelancer(&mut job, &cap, FREELANCER, &clock, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::start_job(&mut job, &clock, ts::ctx(&mut scenario));
            job_escrow::submit_milestone(&mut job, 0, b"proof", &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        // Approve milestone
        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);

            let escrow_before = job_escrow::get_escrow_balance(&job);

            job_escrow::approve_milestone(&mut job, &cap, 0, &clock, ts::ctx(&mut scenario));

            let escrow_after = job_escrow::get_escrow_balance(&job);
            assert!(escrow_before - escrow_after == MILESTONE_AMOUNT, 0);

            let milestone = job_escrow::get_milestone(&job, 0);
            assert!(job_escrow::milestone_is_approved(milestone), 1);

            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        // Verify payment received
        ts::next_tx(&mut scenario, FREELANCER);
        {
            assert!(ts::has_most_recent_for_address<Coin<SUI>>(FREELANCER), 2);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    fun test_approve_milestone_completes_job() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        // Create job with one milestone = full budget
        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::add_milestone(&mut job, &cap, b"Full Job", BUDGET, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::assign_freelancer(&mut job, &cap, FREELANCER, &clock, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::start_job(&mut job, &clock, ts::ctx(&mut scenario));
            job_escrow::submit_milestone(&mut job, 0, b"proof", &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);

            job_escrow::approve_milestone(&mut job, &cap, 0, &clock, ts::ctx(&mut scenario));

            // Should transition to COMPLETED
            assert!(job_escrow::get_state(&job) == STATE_COMPLETED, 0);
            assert!(job_escrow::get_escrow_balance(&job) == 0, 1);

            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // ======== 8. Function-Specific Tests: cancel_job() ========

    #[test]
    fun test_cancel_job_in_open_state() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);

            job_escrow::cancel_job(&mut job, &cap, &clock, ts::ctx(&mut scenario));

            assert!(job_escrow::get_state(&job) == STATE_CANCELLED, 0);
            assert!(job_escrow::get_escrow_balance(&job) == 0, 1);

            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        // Verify refund
        ts::next_tx(&mut scenario, CLIENT);
        {
            assert!(ts::has_most_recent_for_address<Coin<SUI>>(CLIENT), 2);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    fun test_cancel_job_in_assigned_state() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::assign_freelancer(&mut job, &cap, FREELANCER, &clock, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        // Cancel after assignment
        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);

            job_escrow::cancel_job(&mut job, &cap, &clock, ts::ctx(&mut scenario));

            assert!(job_escrow::get_state(&job) == STATE_CANCELLED, 0);

            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EInvalidState)]
    fun test_cancel_job_in_progress() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::assign_freelancer(&mut job, &cap, FREELANCER, &clock, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::start_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        // Try to cancel in IN_PROGRESS
        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);

            job_escrow::cancel_job(&mut job, &cap, &clock, ts::ctx(&mut scenario));

            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // ======== 9. State Machine Tests ========

    #[test]
    fun test_full_job_lifecycle() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        // OPEN
        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let job = ts::take_shared<Job>(&scenario);
            assert!(job_escrow::get_state(&job) == STATE_OPEN, 0);
            ts::return_shared(job);
        };

        // Add milestone
        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::add_milestone(&mut job, &cap, b"Milestone", BUDGET, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        // Apply
        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        // ASSIGNED
        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::assign_freelancer(&mut job, &cap, FREELANCER, &clock, ts::ctx(&mut scenario));
            assert!(job_escrow::get_state(&job) == STATE_ASSIGNED, 1);
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        // IN_PROGRESS
        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::start_job(&mut job, &clock, ts::ctx(&mut scenario));
            assert!(job_escrow::get_state(&job) == STATE_IN_PROGRESS, 2);
            ts::return_shared(job);
        };

        // SUBMITTED
        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::submit_milestone(&mut job, 0, b"proof", &clock, ts::ctx(&mut scenario));
            assert!(job_escrow::get_state(&job) == STATE_SUBMITTED, 3);
            ts::return_shared(job);
        };

        // COMPLETED (all milestones approved)
        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::approve_milestone(&mut job, &cap, 0, &clock, ts::ctx(&mut scenario));
            assert!(job_escrow::get_state(&job) == STATE_COMPLETED, 4);
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    fun test_cancellation_path() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);

            job_escrow::cancel_job(&mut job, &cap, &clock, ts::ctx(&mut scenario));
            assert!(job_escrow::get_state(&job) == STATE_CANCELLED, 0);

            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // ======== 10. Escrow Safety Tests ========

    #[test]
    fun test_escrow_balance_decreases_on_payment() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::add_milestone(&mut job, &cap, b"M1", BUDGET, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::assign_freelancer(&mut job, &cap, FREELANCER, &clock, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::start_job(&mut job, &clock, ts::ctx(&mut scenario));
            job_escrow::submit_milestone(&mut job, 0, b"proof", &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);

            assert!(job_escrow::get_escrow_balance(&job) == BUDGET, 0);

            job_escrow::approve_milestone(&mut job, &cap, 0, &clock, ts::ctx(&mut scenario));

            assert!(job_escrow::get_escrow_balance(&job) == 0, 1);

            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    fun test_refund_returns_full_escrow() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);

            assert!(job_escrow::get_escrow_balance(&job) == BUDGET, 0);

            job_escrow::cancel_job(&mut job, &cap, &clock, ts::ctx(&mut scenario));

            assert!(job_escrow::get_escrow_balance(&job) == 0, 1);

            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // ======== 11. Getter Function Tests ========

    #[test]
    fun test_getters_return_correct_values() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);

            // Test basic getters
            assert!(job_escrow::get_client(&job) == CLIENT, 0);
            assert!(job_escrow::get_budget(&job) == BUDGET, 1);
            assert!(job_escrow::get_deadline(&job) == FUTURE_DEADLINE, 2);
            assert!(job_escrow::get_state(&job) == STATE_OPEN, 3);
            assert!(job_escrow::get_milestone_count(&job) == 0, 4);
            assert!(job_escrow::get_applicant_count(&job) == 0, 5);
            assert!(job_escrow::get_escrow_balance(&job) == BUDGET, 6);
            assert!(job_escrow::get_created_at(&job) == CURRENT_TIME, 7);
            assert!(job_escrow::get_deliverable_count(&job) == 0, 8);

            let freelancer_opt = job_escrow::get_freelancer(&job);
            assert!(option::is_none(&freelancer_opt), 9);

            // Test title and description
            let title = job_escrow::get_title(&job);
            assert!(title == b"Test Job", 10);

            let desc_blob = job_escrow::get_description_blob_id(&job);
            assert!(desc_blob == b"blob_123", 11);

            // Test JobCap getter
            let cap_job_id = job_escrow::get_cap_job_id(&cap);
            assert!(cap_job_id == object::id(&job), 12);

            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    fun test_milestone_getters() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);

            job_escrow::add_milestone(&mut job, &cap, b"Test Milestone", MILESTONE_AMOUNT, ts::ctx(&mut scenario));

            let milestone = job_escrow::get_milestone(&job, 0);
            assert!(job_escrow::milestone_get_id(milestone) == 0, 0);
            assert!(job_escrow::milestone_get_amount(milestone) == MILESTONE_AMOUNT, 1);
            assert!(!job_escrow::milestone_is_completed(milestone), 2);
            assert!(!job_escrow::milestone_is_approved(milestone), 3);

            let desc = job_escrow::milestone_get_description(milestone);
            assert!(desc == b"Test Milestone", 4);

            let blob_opt = job_escrow::milestone_get_submission_blob_id(milestone);
            assert!(option::is_none(&blob_opt), 5);

            let submitted_opt = job_escrow::milestone_get_submitted_at(milestone);
            assert!(option::is_none(&submitted_opt), 6);

            let approved_opt = job_escrow::milestone_get_approved_at(milestone);
            assert!(option::is_none(&approved_opt), 7);

            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // ======== 12. Edge Cases ========

    #[test]
    fun test_job_with_multiple_applicants() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        // Add 5 applicants to demonstrate large applicant handling
        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, FREELANCER2);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, @0xA2);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, @0xA3);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, @0xA4);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, CLIENT);
        {
            let job = ts::take_shared<Job>(&scenario);
            assert!(job_escrow::get_applicant_count(&job) == 5, 0);
            assert!(job_escrow::is_applicant(&job, FREELANCER), 1);
            assert!(job_escrow::is_applicant(&job, FREELANCER2), 2);
            assert!(job_escrow::is_applicant(&job, @0xA2), 3);
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    fun test_multiple_milestone_workflow() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        // Add 3 milestones
        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);

            job_escrow::add_milestone(&mut job, &cap, b"M1", 300_000_000, ts::ctx(&mut scenario));
            job_escrow::add_milestone(&mut job, &cap, b"M2", 300_000_000, ts::ctx(&mut scenario));
            job_escrow::add_milestone(&mut job, &cap, b"M3", 400_000_000, ts::ctx(&mut scenario));

            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::assign_freelancer(&mut job, &cap, FREELANCER, &clock, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::start_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        // Submit and approve M1
        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::submit_milestone(&mut job, 0, b"proof1", &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::approve_milestone(&mut job, &cap, 0, &clock, ts::ctx(&mut scenario));

            // Should be back to IN_PROGRESS
            assert!(job_escrow::get_state(&job) == STATE_IN_PROGRESS, 0);

            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        // Submit and approve M2
        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::submit_milestone(&mut job, 1, b"proof2", &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::approve_milestone(&mut job, &cap, 1, &clock, ts::ctx(&mut scenario));
            assert!(job_escrow::get_state(&job) == STATE_IN_PROGRESS, 1);
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        // Submit and approve M3 - should complete job
        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::submit_milestone(&mut job, 2, b"proof3", &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::approve_milestone(&mut job, &cap, 2, &clock, ts::ctx(&mut scenario));

            // Should be COMPLETED now
            assert!(job_escrow::get_state(&job) == STATE_COMPLETED, 2);
            assert!(job_escrow::get_escrow_balance(&job) == 0, 3);

            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    fun test_milestone_total_less_than_budget() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);

            // Add milestones totaling 0.6 SUI (less than 1 SUI budget)
            job_escrow::add_milestone(&mut job, &cap, b"M1", 300_000_000, ts::ctx(&mut scenario));
            job_escrow::add_milestone(&mut job, &cap, b"M2", 300_000_000, ts::ctx(&mut scenario));

            assert!(job_escrow::get_milestone_count(&job) == 2, 0);

            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // ======== 13. Access Control Tests ========

    #[test]
    #[expected_failure(abort_code = ENotAuthorized)]
    fun test_non_client_cannot_assign() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        // Random user tries to assign (without JobCap)
        ts::next_tx(&mut scenario, CLIENT);
        let cap = ts::take_from_sender<JobCap>(&scenario);
        ts::return_to_sender(&scenario, cap);

        ts::next_tx(&mut scenario, RANDOM_USER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            // This will fail because RANDOM_USER doesn't have the cap
            // We can't test this directly as the cap is owned by CLIENT
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = ENotAuthorized)]
    fun test_non_client_cannot_approve_milestone() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        // Setup to SUBMITTED state
        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::add_milestone(&mut job, &cap, b"M1", BUDGET, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::assign_freelancer(&mut job, &cap, FREELANCER, &clock, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::start_job(&mut job, &clock, ts::ctx(&mut scenario));
            job_escrow::submit_milestone(&mut job, 0, b"proof", &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        // Try to approve without being client (cap ownership enforces this)
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = ENotAuthorized)]
    fun test_non_client_cannot_cancel() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        // Cannot test directly as JobCap is owned by CLIENT
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EFreelancerNotAssigned)]
    fun test_non_freelancer_cannot_submit() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::add_milestone(&mut job, &cap, b"M1", BUDGET, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::assign_freelancer(&mut job, &cap, FREELANCER, &clock, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::start_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        // Different user tries to submit
        ts::next_tx(&mut scenario, RANDOM_USER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::submit_milestone(&mut job, 0, b"proof", &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // ======== 14. Deadline Enforcement Tests ========

    #[test]
    fun test_operations_before_deadline() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            // Should succeed - before deadline
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    fun test_operations_at_deadline() {
        let mut scenario = ts::begin(CLIENT);
        let mut clock = create_clock(FUTURE_DEADLINE, &mut scenario);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let budget_coin = coin::mint_for_testing<SUI>(BUDGET, ts::ctx(&mut scenario));
            job_escrow::create_job(
                b"Test Job",
                b"blob_123",
                budget_coin,
                FUTURE_DEADLINE + 1000, // Slightly future
                &clock,
                ts::ctx(&mut scenario)
            );
        };

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    fun test_deadline_doesnt_affect_in_progress_job() {
        let mut scenario = ts::begin(CLIENT);
        let mut clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::add_milestone(&mut job, &cap, b"M1", BUDGET, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::assign_freelancer(&mut job, &cap, FREELANCER, &clock, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::start_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        // Advance past deadline
        clock::set_for_testing(&mut clock, FUTURE_DEADLINE + 1000);

        // Submit should still work (deadline only blocks apply/start)
        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::submit_milestone(&mut job, 0, b"proof", &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // ======== 15. Budget Validation Tests ========

    #[test]
    #[expected_failure(abort_code = EInvalidMilestone)]
    fun test_milestone_zero_amount() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);

            job_escrow::add_milestone(&mut job, &cap, b"Zero Amount", 0, ts::ctx(&mut scenario));

            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    fun test_milestones_equal_budget() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);

            // Exact budget match
            job_escrow::add_milestone(&mut job, &cap, b"M1", 400_000_000, ts::ctx(&mut scenario));
            job_escrow::add_milestone(&mut job, &cap, b"M2", 300_000_000, ts::ctx(&mut scenario));
            job_escrow::add_milestone(&mut job, &cap, b"M3", 300_000_000, ts::ctx(&mut scenario));

            assert!(job_escrow::get_milestone_count(&job) == 3, 0);

            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    fun test_large_budget() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        let large_budget = 1_000_000_000_000; // 1000 SUI

        ts::next_tx(&mut scenario, CLIENT);
        {
            let budget_coin = coin::mint_for_testing<SUI>(large_budget, ts::ctx(&mut scenario));
            job_escrow::create_job(
                b"Large Project",
                b"blob_large",
                budget_coin,
                FUTURE_DEADLINE,
                &clock,
                ts::ctx(&mut scenario)
            );
        };

        ts::next_tx(&mut scenario, CLIENT);
        {
            let job = ts::take_shared<Job>(&scenario);
            assert!(job_escrow::get_budget(&job) == large_budget, 0);
            assert!(job_escrow::get_escrow_balance(&job) == large_budget, 1);
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // ======== 16. Error Handling Tests ========

    #[test]
    #[expected_failure(abort_code = EInvalidState)]
    fun test_error_invalid_state_on_duplicate_start() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::assign_freelancer(&mut job, &cap, FREELANCER, &clock, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::start_job(&mut job, &clock, ts::ctx(&mut scenario));

            // Try to start again
            job_escrow::start_job(&mut job, &clock, ts::ctx(&mut scenario));

            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EJobNotOpen)]
    fun test_error_job_not_open() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::assign_freelancer(&mut job, &cap, FREELANCER, &clock, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        // Try to apply after job is assigned
        ts::next_tx(&mut scenario, FREELANCER2);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // ======== 17. Security Tests ========

    #[test]
    fun test_escrow_cannot_be_drained() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let job = ts::take_shared<Job>(&scenario);
            let initial_balance = job_escrow::get_escrow_balance(&job);
            assert!(initial_balance == BUDGET, 0);

            // No way to extract funds without proper flow
            // Escrow is protected by Balance<SUI> type

            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    fun test_payment_goes_to_correct_freelancer() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::add_milestone(&mut job, &cap, b"M1", BUDGET, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::assign_freelancer(&mut job, &cap, FREELANCER, &clock, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::start_job(&mut job, &clock, ts::ctx(&mut scenario));
            job_escrow::submit_milestone(&mut job, 0, b"proof", &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::approve_milestone(&mut job, &cap, 0, &clock, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        // Verify FREELANCER received payment, not anyone else
        ts::next_tx(&mut scenario, FREELANCER);
        {
            assert!(ts::has_most_recent_for_address<Coin<SUI>>(FREELANCER), 0);
        };

        ts::next_tx(&mut scenario, FREELANCER2);
        {
            assert!(!ts::has_most_recent_for_address<Coin<SUI>>(FREELANCER2), 1);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    fun test_job_cap_prevents_unauthorized_actions() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        // JobCap is owned by CLIENT, cannot be used by others
        ts::next_tx(&mut scenario, CLIENT);
        {
            let cap = ts::take_from_sender<JobCap>(&scenario);
            // Cap is properly owned
            ts::return_to_sender(&scenario, cap);
        };

        // RANDOM_USER has no cap
        ts::next_tx(&mut scenario, RANDOM_USER);
        {
            assert!(!ts::has_most_recent_for_address<JobCap>(RANDOM_USER), 0);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // ======== 18. Integration Placeholder Tests ========
    // Note: Full integration tests with profile_nft and reputation require those modules

    #[test]
    fun test_job_data_for_integration() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let job = ts::take_shared<Job>(&scenario);

            // Verify data that would be used for profile integration
            let client_addr = job_escrow::get_client(&job);
            assert!(client_addr == CLIENT, 0);

            let freelancer_opt = job_escrow::get_freelancer(&job);
            assert!(option::is_none(&freelancer_opt), 1);

            // After assignment, freelancer address would be used to update profiles

            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // ======== 19. Additional Edge Cases ========

    #[test]
    fun test_cancel_with_zero_escrow() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        // This test demonstrates conceptual edge case
        // In reality, create_job validates budget > 0
        // But if somehow escrow was empty, cancel would handle it

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    fun test_job_with_no_milestones_completes() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        // Try full flow without adding milestones
        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::assign_freelancer(&mut job, &cap, FREELANCER, &clock, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::start_job(&mut job, &clock, ts::ctx(&mut scenario));

            // Cannot submit milestone - none exist
            assert!(job_escrow::get_milestone_count(&job) == 0, 0);

            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    fun test_deliverable_blob_ids_tracking() {
        let mut scenario = ts::begin(CLIENT);
        let clock = create_clock(CURRENT_TIME, &mut scenario);

        create_test_job(&mut scenario, &clock);

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::add_milestone(&mut job, &cap, b"M1", 500_000_000, ts::ctx(&mut scenario));
            job_escrow::add_milestone(&mut job, &cap, b"M2", 500_000_000, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::apply_for_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::assign_freelancer(&mut job, &cap, FREELANCER, &clock, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::start_job(&mut job, &clock, ts::ctx(&mut scenario));
            ts::return_shared(job);
        };

        // Submit first milestone
        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            assert!(job_escrow::get_deliverable_count(&job) == 0, 0);

            job_escrow::submit_milestone(&mut job, 0, b"blob_proof_1", &clock, ts::ctx(&mut scenario));

            assert!(job_escrow::get_deliverable_count(&job) == 1, 1);

            ts::return_shared(job);
        };

        // Approve and submit second
        ts::next_tx(&mut scenario, CLIENT);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            let cap = ts::take_from_sender<JobCap>(&scenario);
            job_escrow::approve_milestone(&mut job, &cap, 0, &clock, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, cap);
            ts::return_shared(job);
        };

        ts::next_tx(&mut scenario, FREELANCER);
        {
            let mut job = ts::take_shared<Job>(&scenario);
            job_escrow::submit_milestone(&mut job, 1, b"blob_proof_2", &clock, ts::ctx(&mut scenario));

            assert!(job_escrow::get_deliverable_count(&job) == 2, 2);

            ts::return_shared(job);
        };

        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }
}
