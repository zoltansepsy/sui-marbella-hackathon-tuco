/// Minimal test for zkLogin profile creation
#[test_only]
module zk_freelance::profile_nft_tests_minimal {
    use sui::test_scenario::{Self as ts};
    use sui::clock;
    use zk_freelance::profile_nft::{Self, Profile, ProfileCap};

    const USER_A: address = @0xA;

    #[test]
    fun test_create_profile_with_zklogin() {
        let mut scenario = ts::begin(USER_A);

        // Initialize registry
        profile_nft::init_for_testing(ts::ctx(&mut scenario));

        ts::next_tx(&mut scenario, USER_A);
        {
            let mut registry = ts::take_shared(&scenario);
            let clock = clock::create_for_testing(ts::ctx(&mut scenario));

            profile_nft::create_profile(
                &mut registry,
                0, // FREELANCER
                b"google_oauth_sub_12345",
                b"user@example.com",
                b"testuser",
                b"Test User",
                b"Test bio",
                vector[b"Rust", b"Move"],
                b"avatar.png",
                &clock,
                ts::ctx(&mut scenario)
            );

            clock::destroy_for_testing(clock);
            ts::return_shared(registry);
        };

        // Verify
        ts::next_tx(&mut scenario, USER_A);
        {
            let profile = ts::take_from_sender<Profile>(&scenario);
            let cap = ts::take_from_sender<ProfileCap>(&scenario);

            assert!(profile_nft::get_owner(&profile) == USER_A);
            assert!(profile_nft::get_zklogin_sub(&profile) == std::string::utf8(b"google_oauth_sub_12345"));
            assert!(profile_nft::get_email(&profile) == std::string::utf8(b"user@example.com"));

            ts::return_to_sender(&scenario, profile);
            ts::return_to_sender(&scenario, cap);
        };

        ts::end(scenario);
    }
}
