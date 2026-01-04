#!/bin/bash
# Test suite for common-workflows.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../launchpad/scripts/common-workflows.sh"

# Handle staging flag
STAGING_FLAG=""
if [[ "$1" == "-staging" ]]; then
    STAGING_FLAG="-staging"
    echo "Using Launchpad STAGING server for write operations"
fi

# Override lp-api for testing:
# 1. Adds -staging flag if requested (except for GET operations or Bug #1)
# 2. Intercepts write operations for DRY RUN unless on staging
# 3. Uses local binary
lp-api() {
    local args=("$@")
    local flag=$STAGING_FLAG
    local method="$1"
    local LP_API_BIN="$SCRIPT_DIR/../lp-api"
    
    # Check if local binary exists, otherwise use system one
    if [ ! -f "$LP_API_BIN" ]; then
        LP_API_BIN="lp-api"
    fi
    
    # Route specific read-only test cases to production
    for arg in "${args[@]}"; do
        if [[ "$arg" == "bugs/1" || "$arg" == "ubuntu" || "$arg" == "cloud-init" ]]; then
            flag=""
            break
        fi
    done

    # Check if first arg is a method we want to dry-run
    case "$method" in
        post|patch|put|delete)
            if [[ -z "$flag" ]]; then
                echo "DRY RUN: lp-api $flag ${args[*]}"
                return 0
            fi
            ;;
    esac
    
    # Execute real command
    "$LP_API_BIN" $flag "${args[@]}"
}

# Helper functions for testing
assert_pass() {
    if [ $? -eq 0 ]; then
        echo "PASS: $1"
    else
        echo "FAIL: $1"
        exit 1
    fi
}

assert_fail() {
    if [ $? -ne 0 ]; then
        echo "PASS: $1 (Expected Failure)"
    else
        echo "FAIL: $1 (Expected Failure but Succeeded)"
        exit 1
    fi
}

echo "=== Starting Test Suite for common-workflows.sh ==="

# Section: Bug Workflows
echo -e "\n--- Bug Workflows ---"

# Use bug #1 for testing (well-known public bug) - Always Production
TEST_BUG_ID=1

echo "Testing lp_bug_info $TEST_BUG_ID (Production)..."
output=$(lp_bug_info "$TEST_BUG_ID")
if [ $? -eq 0 ] && echo "$output" | jq -e '.id == 1' > /dev/null; then
    echo "PASS: lp_bug_info"
else
    echo "FAIL: lp_bug_info"
    echo "$output"
    exit 1
fi

echo "Testing lp_search_bugs ubuntu (Production)..."
# Search for bugs with status New in ubuntu project
output=$(lp_search_bugs ubuntu New)
if [ $? -eq 0 ] && echo "$output" | jq -e '.entries != null' > /dev/null; then
    echo "PASS: lp_search_bugs"
else
    echo "FAIL: lp_search_bugs"
    echo "$output"
    exit 1
fi

echo "Testing lp_count_bugs ubuntu (Production)..."
output=$(lp_count_bugs ubuntu New)
if [ $? -eq 0 ] && [[ "$output" =~ ^[0-9]+$ ]]; then
    echo "PASS: lp_count_bugs (Count: $output)"
else
    echo "FAIL: lp_count_bugs"
    echo "$output"
    exit 1
fi

echo "Testing lp_bug_has_tag $TEST_BUG_ID (Production)..."
lp_bug_has_tag "$TEST_BUG_ID" non-existent-tag-$(date +%s) | grep -q "false"
assert_pass "lp_bug_has_tag (non-existent)"

echo "Testing lp_bug_task_status $TEST_BUG_ID ubuntu (Production)..."
output=$(lp_bug_task_status "$TEST_BUG_ID" ubuntu)
if [ $? -eq 0 ] && [ -n "$output" ]; then
    echo "PASS: lp_bug_task_status ($output)"
else
    echo "FAIL: lp_bug_task_status"
    echo "$output"
    exit 1
fi

echo "Testing lp_get_bug_tasks $TEST_BUG_ID (Production)..."
output=$(lp_get_bug_tasks "$TEST_BUG_ID")
if [ $? -eq 0 ] && [ -n "$output" ]; then
    echo "PASS: lp_get_bug_tasks"
else
    echo "FAIL: lp_get_bug_tasks"
    echo "$output"
    exit 1
fi

if [[ -z "$STAGING_FLAG" ]]; then
    echo "Testing lp_bug_comment $TEST_BUG_ID (Dry Run)..."
    output=$(lp_bug_comment "$TEST_BUG_ID" "Test comment" 2>&1)
    if echo "$output" | grep -q "DRY RUN: lp-api  post bugs/1 ws.op=newMessage content=Test comment"; then
        echo "PASS: lp_bug_comment"
    else
        echo "FAIL: lp_bug_comment"
        echo "Output: $output"
        exit 1
    fi

    echo "Testing lp_bug_update_tags $TEST_BUG_ID (Dry Run)..."
    output=$(lp_bug_update_tags "$TEST_BUG_ID" tag1 tag2 2>&1)
    if echo "$output" | grep -q "DRY RUN: lp-api  patch bugs/1 tags:=" && echo "$output" | grep -q "tag1" && echo "$output" | grep -q "tag2"; then
        echo "PASS: lp_bug_update_tags"
    else
        echo "FAIL: lp_bug_update_tags"
        echo "Output: $output"
        exit 1
    fi

    echo "Testing lp_bug_subscribe $TEST_BUG_ID (Dry Run)..."
    output=$(lp_bug_subscribe "$TEST_BUG_ID" 2>&1)
    if echo "$output" | grep -q "DRY RUN: lp-api  post bugs/1 ws.op=subscribe person="; then
        echo "PASS: lp_bug_subscribe"
    else
        echo "FAIL: lp_bug_subscribe"
        echo "Output: $output"
        exit 1
    fi
else
    STAGING_BUG_ID=1938274
    echo "Testing lp_bug_comment $STAGING_BUG_ID (REAL on Staging)..."
lp_bug_comment "$STAGING_BUG_ID" "Test comment from lp-api test suite at $(date)"
    assert_pass "lp_bug_comment (Staging)"
    
    echo "Testing lp_bug_update_tags $STAGING_BUG_ID (REAL on Staging)..."
    lp_bug_update_tags "$STAGING_BUG_ID" test-tag-$(date +%s)
    assert_pass "lp_bug_update_tags (Staging)"

    echo "Testing lp_bug_subscribe $STAGING_BUG_ID (REAL on Staging)..."
    lp_bug_subscribe "$STAGING_BUG_ID"
    assert_pass "lp_bug_subscribe (Staging)"
fi

# Section: Build Workflows
echo -e "\n--- Build Workflows ---"
echo "TODO: Add build workflow tests"

# Section: Package Workflows
echo -e "\n--- Package Workflows ---"
echo "TODO: Add package workflow tests"

# Section: PPA/Person/Team Workflows
echo -e "\n--- PPA/Person/Team Workflows ---"
echo "TODO: Add PPA/Person/Team workflow tests"

# Section: Utility Functions
echo -e "\n--- Utility Functions ---"

# Existing tests for lp_list_series
echo "Testing lp_list_series..."
output=$(lp_list_series ubuntu 2>&1)
if [ $? -eq 0 ] && echo "$output" | grep -q "Series"; then
    echo "PASS: lp_list_series (ubuntu) runs and has headers"
else
    echo "FAIL: lp_list_series (ubuntu) failed"
    echo "$output"
    exit 1
fi

lp_list_series cloud-init > /dev/null 2>&1
assert_pass "lp_list_series cloud-init runs"

echo -e "\n=== Test Suite Complete ==="