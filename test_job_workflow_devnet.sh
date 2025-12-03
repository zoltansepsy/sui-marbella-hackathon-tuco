#!/bin/bash
# test_job_workflow_devnet.sh
# Tests the job workflow on devnet to reproduce the ownership error

# Don't exit on error - we want to see what happens
set +e

# ========== CONFIGURATION ==========
# MODIFY THESE ADDRESSES FOR YOUR TEST
CLIENT_ADDRESS="0x036a00032023f00dfe8a64e1e1f254e740ce5ef6ed92e8aed344bff23a71013d"
FREELANCER_ADDRESS="0xfdcb8d759f590a675891052e2f7b5bef56e5f4e348ce55003ce4194cafdea65a"

PACKAGE_ID="0x78a9a8d37a5e586ad4b0c9bbe712894c2b8eeb865e408079b99f43967e36e9c1"
IDENTITY_REGISTRY_ID="0x2252a6848868900729573bc599767529b439a5914eaff3ce7a6e832e631f5326"
# ===================================

CLOCK="0x6"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper function to extract JSON from sui client output (removes warning lines)
extract_json() {
    # Remove warning lines that appear before JSON output
    grep -v '^\[warning\]'
}

# Helper function to validate object belongs to current package
validate_object_package() {
    local obj_id=$1
    local expected_module=$2  # e.g., "profile_nft::Profile"
    # The JSON output uses .type (not .data.type)
    local actual_type=$(sui client object $obj_id --json 2>/dev/null | extract_json | jq -r '.type // empty')

    if [ -z "$actual_type" ]; then
        echo -e "${RED}ERROR: Could not get type for object $obj_id${NC}"
        return 1
    fi

    local expected_type="${PACKAGE_ID}::${expected_module}"
    if [ "$actual_type" != "$expected_type" ]; then
        echo -e "${YELLOW}Package mismatch for object $obj_id${NC}"
        echo "  Expected: $expected_type"
        echo "  Actual:   $actual_type"
        return 1
    fi
    return 0
}

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Job Workflow Devnet Test${NC}"
echo -e "${YELLOW}========================================${NC}"

# ========== STEP 0: Check dependencies ==========
echo -e "\n${GREEN}[0/8] Checking dependencies...${NC}"

if ! command -v jq &> /dev/null; then
    echo -e "${RED}ERROR: 'jq' is not installed${NC}"
    echo ""
    echo "Install it with:"
    echo "  sudo apt install jq"
    echo ""
    exit 1
fi

echo "jq: OK"

# ========== STEP 1: Validate configuration ==========
echo -e "\n${GREEN}[1/8] Validating configuration...${NC}"

if [ "$CLIENT_ADDRESS" == "0xYOUR_CLIENT_ADDRESS_HERE" ] || [ "$FREELANCER_ADDRESS" == "0xYOUR_FREELANCER_ADDRESS_HERE" ]; then
    echo -e "${RED}ERROR: Please set CLIENT_ADDRESS and FREELANCER_ADDRESS at the top of the script${NC}"
    echo ""
    echo "You can find your addresses with: sui client addresses"
    echo ""
    echo "Example:"
    echo "  CLIENT_ADDRESS=\"0x1234...abcd\""
    echo "  FREELANCER_ADDRESS=\"0x5678...efgh\""
    exit 1
fi

if [ "$CLIENT_ADDRESS" == "$FREELANCER_ADDRESS" ]; then
    echo -e "${RED}ERROR: CLIENT_ADDRESS and FREELANCER_ADDRESS must be different${NC}"
    exit 1
fi

# Check if package exists
echo "Checking if package exists on network..."
PACKAGE_CHECK=$(sui client object $PACKAGE_ID --json 2>&1) || true
if echo "$PACKAGE_CHECK" | grep -q "does not exist\|Object not found"; then
    echo -e "${RED}ERROR: Package $PACKAGE_ID does not exist on the network${NC}"
    echo ""
    echo "You need to deploy the contract first:"
    echo "  cd move/zk_freelance"
    echo "  sui client publish --gas-budget 500000000"
    echo ""
    echo "Then update PACKAGE_ID and IDENTITY_REGISTRY_ID in this script"
    exit 1
fi
echo "Package: OK"

sui client envs
echo ""
echo "CLIENT_ADDRESS: $CLIENT_ADDRESS"
echo "FREELANCER_ADDRESS: $FREELANCER_ADDRESS"

# ========== STEP 2: Verify addresses exist in keystore ==========
echo -e "\n${GREEN}[2/8] Verifying addresses in keystore...${NC}"

echo "Available addresses:"
sui client addresses

# Switch to client to verify it exists
echo "Switching to CLIENT..."
sui client switch --address $CLIENT_ADDRESS || {
    echo -e "${RED}ERROR: CLIENT_ADDRESS not found in keystore${NC}"
    exit 1
}

# Switch to freelancer to verify it exists
echo "Switching to FREELANCER..."
sui client switch --address $FREELANCER_ADDRESS || {
    echo -e "${RED}ERROR: FREELANCER_ADDRESS not found in keystore${NC}"
    exit 1
}

# Switch back to client
sui client switch --address $CLIENT_ADDRESS

# ========== STEP 3: Create CLIENT profile ==========
echo -e "\n${GREEN}[3/8] Creating CLIENT profile...${NC}"

# Check if client already has a profile with EXACT package match (not just any Profile)
# This ensures we use profiles from the current package version
CLIENT_PROFILE_ID=$(sui client objects --json 2>/dev/null | extract_json | jq -r --arg pkg "$PACKAGE_ID" '.[] | select(.data.type == ($pkg + "::profile_nft::Profile")) | .data.objectId' | head -1)

if [ -n "$CLIENT_PROFILE_ID" ] && [ "$CLIENT_PROFILE_ID" != "null" ]; then
    echo "Client already has profile with current package: $CLIENT_PROFILE_ID"
    # Validate the profile package just to be sure
    if ! validate_object_package "$CLIENT_PROFILE_ID" "profile_nft::Profile"; then
        echo -e "${YELLOW}Profile validation failed, will create new profile${NC}"
        CLIENT_PROFILE_ID=""
    fi
fi

if [ -z "$CLIENT_PROFILE_ID" ] || [ "$CLIENT_PROFILE_ID" == "null" ]; then
    echo "Creating new client profile..."
    CREATE_PROFILE_RESULT=$(sui client call \
        --package $PACKAGE_ID \
        --module profile_nft \
        --function create_profile \
        --args \
            $IDENTITY_REGISTRY_ID \
            1 \
            '"zklogin_client_test_sub_v2"' \
            '"client@test.com"' \
            '"TestClient"' \
            '"Test Client Real Name"' \
            '"I am a test client"' \
            '["hiring", "tech"]' \
            '"avatar_blob_id"' \
            $CLOCK \
        --gas-budget 100000000 \
        --json 2>&1) || true

    # Extract profile ID directly from transaction result
    CREATE_PROFILE_JSON=$(echo "$CREATE_PROFILE_RESULT" | extract_json)
    if echo "$CREATE_PROFILE_JSON" | jq -e '.effects.status.status == "success"' > /dev/null 2>&1; then
        CLIENT_PROFILE_ID=$(echo "$CREATE_PROFILE_JSON" | jq -r --arg pkg "$PACKAGE_ID" '.objectChanges[] | select(.objectType == ($pkg + "::profile_nft::Profile")) | .objectId' | head -1)
        echo -e "${GREEN}Profile created successfully: $CLIENT_PROFILE_ID${NC}"
    else
        echo -e "${RED}Profile creation failed!${NC}"
        echo "$CREATE_PROFILE_JSON" | jq '.effects.status' 2>/dev/null || echo "$CREATE_PROFILE_RESULT"
    fi

    sleep 2
fi

echo "CLIENT_PROFILE_ID: $CLIENT_PROFILE_ID"

if [ -z "$CLIENT_PROFILE_ID" ] || [ "$CLIENT_PROFILE_ID" == "null" ]; then
    echo -e "${RED}ERROR: Failed to get CLIENT_PROFILE_ID${NC}"
    exit 1
fi

# ========== STEP 4: Create FREELANCER profile ==========
echo -e "\n${GREEN}[4/8] Creating FREELANCER profile...${NC}"

sui client switch --address $FREELANCER_ADDRESS

# Check if freelancer already has a profile with EXACT package match
FREELANCER_PROFILE_ID=$(sui client objects --json 2>/dev/null | extract_json | jq -r --arg pkg "$PACKAGE_ID" '.[] | select(.data.type == ($pkg + "::profile_nft::Profile")) | .data.objectId' | head -1)

if [ -n "$FREELANCER_PROFILE_ID" ] && [ "$FREELANCER_PROFILE_ID" != "null" ]; then
    echo "Freelancer already has profile with current package: $FREELANCER_PROFILE_ID"
    # Validate the profile package just to be sure
    if ! validate_object_package "$FREELANCER_PROFILE_ID" "profile_nft::Profile"; then
        echo -e "${YELLOW}Profile validation failed, will create new profile${NC}"
        FREELANCER_PROFILE_ID=""
    fi
fi

if [ -z "$FREELANCER_PROFILE_ID" ] || [ "$FREELANCER_PROFILE_ID" == "null" ]; then
    echo "Creating new freelancer profile..."
    CREATE_FL_PROFILE_RESULT=$(sui client call \
        --package $PACKAGE_ID \
        --module profile_nft \
        --function create_profile \
        --args \
            $IDENTITY_REGISTRY_ID \
            0 \
            '"zklogin_freelancer_test_sub_v2"' \
            '"freelancer@test.com"' \
            '"TestFreelancer"' \
            '"Test Freelancer Real Name"' \
            '"I am a test freelancer"' \
            '["move", "rust", "sui"]' \
            '"avatar_blob_id"' \
            $CLOCK \
        --gas-budget 100000000 \
        --json 2>&1) || true

    # Extract profile ID directly from transaction result
    CREATE_FL_PROFILE_JSON=$(echo "$CREATE_FL_PROFILE_RESULT" | extract_json)
    if echo "$CREATE_FL_PROFILE_JSON" | jq -e '.effects.status.status == "success"' > /dev/null 2>&1; then
        FREELANCER_PROFILE_ID=$(echo "$CREATE_FL_PROFILE_JSON" | jq -r --arg pkg "$PACKAGE_ID" '.objectChanges[] | select(.objectType == ($pkg + "::profile_nft::Profile")) | .objectId' | head -1)
        echo -e "${GREEN}Freelancer profile created successfully: $FREELANCER_PROFILE_ID${NC}"
    else
        echo -e "${RED}Freelancer profile creation failed!${NC}"
        echo "$CREATE_FL_PROFILE_JSON" | jq '.effects.status' 2>/dev/null || echo "$CREATE_FL_PROFILE_RESULT"
    fi

    sleep 2
fi

echo "FREELANCER_PROFILE_ID: $FREELANCER_PROFILE_ID"

if [ -z "$FREELANCER_PROFILE_ID" ] || [ "$FREELANCER_PROFILE_ID" == "null" ]; then
    echo -e "${RED}ERROR: Failed to get FREELANCER_PROFILE_ID${NC}"
    exit 1
fi

# Switch back to client
sui client switch --address $CLIENT_ADDRESS

# ========== STEP 5: Create a Job as CLIENT ==========
echo -e "\n${GREEN}[5/8] Creating job as CLIENT...${NC}"

# Get a coin for payment (1 SUI = 1000000000 MIST)
CLIENT_COIN=$(sui client gas --json | jq -r '.[0].gasCoinId')
echo "Using coin: $CLIENT_COIN"

# Calculate deadline (30 days from now in milliseconds)
DEADLINE=$(($(date +%s) * 1000 + 30 * 24 * 60 * 60 * 1000))

# Split coin for job budget (0.1 SUI)
echo "Splitting coin for job budget..."
SPLIT_RESULT=$(sui client split-coin \
    --coin-id $CLIENT_COIN \
    --amounts 100000000 \
    --gas-budget 50000000 \
    --json)

sleep 2

# Get the split coin
BUDGET_COIN=$(sui client gas --json | jq -r '.[] | select(.mistBalance == 100000000) | .gasCoinId' | head -1)
if [ -z "$BUDGET_COIN" ]; then
    BUDGET_COIN=$(sui client gas --json | jq -r '.[1].gasCoinId')
fi
echo "Budget coin: $BUDGET_COIN"

# Validate CLIENT_PROFILE before calling create_job
echo "Validating CLIENT_PROFILE package..."
if ! validate_object_package "$CLIENT_PROFILE_ID" "profile_nft::Profile"; then
    echo -e "${RED}ERROR: CLIENT_PROFILE has wrong package version!${NC}"
    echo "The profile was created with a different package deployment."
    echo "You need to create a new profile with the current package."
    echo ""
    echo "Possible solutions:"
    echo "  1. Delete the old profile and run this script again"
    echo "  2. Deploy a new package and update PACKAGE_ID in this script"
    exit 1
fi
echo -e "${GREEN}Profile validation passed!${NC}"

echo "Creating job..."
JOB_RESULT=$(sui client call \
    --package $PACKAGE_ID \
    --module job_escrow \
    --function create_job \
    --args \
        $CLIENT_PROFILE_ID \
        '"Test Job Title"' \
        '"description_blob_id"' \
        $BUDGET_COIN \
        $DEADLINE \
        $CLOCK \
    --gas-budget 100000000 \
    --json 2>&1) || true

sleep 3

# Extract only JSON from result (remove warning lines)
JOB_JSON=$(echo "$JOB_RESULT" | extract_json)

# Check if transaction succeeded
if ! echo "$JOB_JSON" | jq -e '.effects.status.status == "success"' > /dev/null 2>&1; then
    echo -e "${RED}ERROR: create_job transaction failed${NC}"
    # Show the error details
    echo "$JOB_JSON" | jq '.effects.status' 2>/dev/null || echo "$JOB_RESULT"
    exit 1
fi

echo -e "${GREEN}Transaction succeeded!${NC}"

# Get Job ID (shared object) - try multiple extraction methods
# Method 1: From objectChanges (look for ::Job type)
JOB_ID=$(echo "$JOB_JSON" | jq -r '.objectChanges[] | select(.objectType != null and (.objectType | endswith("::Job"))) | .objectId' 2>/dev/null | head -1)

# Method 2: From events if method 1 failed
if [ -z "$JOB_ID" ] || [ "$JOB_ID" == "null" ]; then
    echo "Trying to extract JOB_ID from events..."
    JOB_ID=$(echo "$JOB_JSON" | jq -r '.events[] | select(.type | contains("JobCreated")) | .parsedJson.job_id' 2>/dev/null | head -1)
fi

# Method 3: From shared object in created array
if [ -z "$JOB_ID" ] || [ "$JOB_ID" == "null" ]; then
    echo "Trying to extract JOB_ID from created shared objects..."
    JOB_ID=$(echo "$JOB_JSON" | jq -r '.effects.created[] | select(.owner.Shared) | .reference.objectId' 2>/dev/null | head -1)
fi

# Get JobCap ID from same transaction result (not from all owned objects)
JOB_CAP_ID=$(echo "$JOB_JSON" | jq -r '.objectChanges[] | select(.objectType != null and (.objectType | endswith("::JobCap"))) | .objectId' 2>/dev/null | head -1)

# Fallback: query owned objects if not found in transaction (with exact package match)
if [ -z "$JOB_CAP_ID" ] || [ "$JOB_CAP_ID" == "null" ]; then
    echo "Trying to extract JOB_CAP_ID from owned objects..."
    JOB_CAP_ID=$(sui client objects --json | extract_json | jq -r --arg pkg "$PACKAGE_ID" '.[] | select(.data.type == ($pkg + "::job_escrow::JobCap")) | .data.objectId' | head -1)
fi

echo "JOB_ID: $JOB_ID"
echo "JOB_CAP_ID: $JOB_CAP_ID"

if [ -z "$JOB_ID" ] || [ "$JOB_ID" == "null" ]; then
    echo -e "${RED}ERROR: Failed to get JOB_ID${NC}"
    exit 1
fi

if [ -z "$JOB_CAP_ID" ] || [ "$JOB_CAP_ID" == "null" ]; then
    echo -e "${RED}ERROR: Failed to get JOB_CAP_ID${NC}"
    exit 1
fi

# ========== STEP 6: Apply for job as FREELANCER ==========
echo -e "\n${GREEN}[6/8] Applying for job as FREELANCER...${NC}"

sui client switch --address $FREELANCER_ADDRESS

echo "Applying for job..."
APPLY_RESULT=$(sui client call \
    --package $PACKAGE_ID \
    --module job_escrow \
    --function apply_for_job \
    --args \
        $JOB_ID \
        $FREELANCER_PROFILE_ID \
        $CLOCK \
    --gas-budget 100000000 \
    --json 2>&1) || true

echo "$APPLY_RESULT"
sleep 2

# Switch back to client
sui client switch --address $CLIENT_ADDRESS

# ========== STEP 7: Assign freelancer as CLIENT ==========
echo -e "\n${GREEN}[7/8] Assigning freelancer as CLIENT...${NC}"
echo -e "${YELLOW}This should now SUCCEED - freelancer profile is not needed for assign!${NC}"

echo ""
echo "Calling assign_freelancer with:"
echo "  JOB_ID: $JOB_ID"
echo "  JOB_CAP_ID: $JOB_CAP_ID"
echo "  FREELANCER_ADDRESS: $FREELANCER_ADDRESS"
echo ""

# assign_freelancer no longer requires freelancer profile
ASSIGN_RESULT=$(sui client call \
    --package $PACKAGE_ID \
    --module job_escrow \
    --function assign_freelancer \
    --args \
        $JOB_ID \
        $JOB_CAP_ID \
        $FREELANCER_ADDRESS \
        $CLOCK \
    --gas-budget 100000000 \
    --json 2>&1) || true

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}ASSIGN RESULT:${NC}"
echo -e "${GREEN}========================================${NC}"
echo "$ASSIGN_RESULT"

# Check if assignment succeeded
if echo "$ASSIGN_RESULT" | grep -q "\"status\": \"success\""; then
    echo ""
    echo -e "${GREEN}SUCCESS: Freelancer assigned!${NC}"
else
    echo ""
    echo -e "${RED}FAILED: Check output above${NC}"
    exit 1
fi

sleep 2

# ========== STEP 8: Start job as FREELANCER ==========
echo -e "\n${GREEN}[8/8] Starting job as FREELANCER...${NC}"
echo -e "${YELLOW}Freelancer calls start_job with their own profile${NC}"

sui client switch --address $FREELANCER_ADDRESS

echo ""
echo "Calling start_job with:"
echo "  JOB_ID: $JOB_ID"
echo "  FREELANCER_PROFILE_ID: $FREELANCER_PROFILE_ID"
echo ""

START_RESULT=$(sui client call \
    --package $PACKAGE_ID \
    --module job_escrow \
    --function start_job \
    --args \
        $JOB_ID \
        $FREELANCER_PROFILE_ID \
        $CLOCK \
    --gas-budget 100000000 \
    --json 2>&1) || true

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}START RESULT:${NC}"
echo -e "${GREEN}========================================${NC}"
echo "$START_RESULT"

# Check if start succeeded
if echo "$START_RESULT" | grep -q "\"status\": \"success\""; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}SUCCESS: Job workflow completed!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "The job is now IN_PROGRESS. The freelancer can submit milestones."
    echo ""
    echo "Fix implemented:"
    echo "  1. assign_freelancer - Client assigns without needing freelancer's profile"
    echo "  2. start_job - Freelancer starts work and provides their own profile"
else
    echo ""
    echo -e "${RED}FAILED: Check output above${NC}"
fi

echo ""
echo "========================================"
echo "Test completed!"
echo "========================================"
