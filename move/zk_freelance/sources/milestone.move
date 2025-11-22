/// Milestone Module
/// Basic utility functions for milestone management
///
/// NOTE: All core milestone functionality is implemented in job_escrow.move.
/// This module provides helper utilities for UI/frontend integration only.
/// Milestones are stored in job_escrow.move as Table<u64, Milestone>.

module zk_freelance::milestone {
    // This module is intentionally minimal.
    // All milestone operations (create, submit, approve) are handled in job_escrow.move
    // which provides 20+ getter functions for frontend integration.

    // Future: Add helper/utility functions here if needed for UI convenience
}
