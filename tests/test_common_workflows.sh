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

CURRENT_SERIES=$(lp-api get ubuntu | lp-api .current_series_link | jq -r .name)
TEST_LIVEFS="~ubuntu-cdimage/+livefs/ubuntu/${CURRENT_SERIES}/ubuntu"

echo "Testing lp_latest_build $TEST_LIVEFS..."
build_info=$(lp_latest_build "$TEST_LIVEFS" 2>/dev/null)
build_link=$(echo "$build_info" | jq -r .self_link)
if [[ $? -eq 0 && "$build_link" == http* ]]; then
    echo "PASS: lp_latest_build ($build_link)"
else
    echo "FAIL: lp_latest_build"
    echo "Output: $build_info"
    exit 1
fi

echo "Testing lp_build_status $build_link..."
status=$(lp_build_status "$build_link" 2>/dev/null)
if [[ $? -eq 0 && -n "$status" ]]; then
    echo "PASS: lp_build_status ($status)"
else
    echo "FAIL: lp_build_status"
    echo "Output: $status"
    exit 1
fi

echo "Testing lp_failed_builds $TEST_LIVEFS..."
failed_builds=$(lp_failed_builds "$TEST_LIVEFS" 2>/dev/null)
if [[ $? -eq 0 ]]; then
    echo "PASS: lp_failed_builds"
else
    echo "FAIL: lp_failed_builds"
    exit 1
fi

echo "Testing lp_download_build_artifacts $build_link (Dry Run)..."
# Mock lp-api download to avoid large downloads
lp-api() {
    local args=("$@")
    if [[ "$1" == "download" ]]; then
        echo "DRY RUN: lp-api download ${args[1]}"
        return 0
    fi
    # Use the outer wrapper logic for others
    local flag=$STAGING_FLAG
    local method="$1"
    local LP_API_BIN="$SCRIPT_DIR/../lp-api"
    [ ! -f "$LP_API_BIN" ] && LP_API_BIN="lp-api"
    for arg in "${args[@]}"; do
        if [[ "$arg" == "bugs/1" || "$arg" == "ubuntu" || "$arg" == "cloud-init" ]]; then
            flag=""
            break
        fi
    done
    "$LP_API_BIN" $flag "${args[@]}"
}

output=$(lp_download_build_artifacts "$build_link" 2>&1)
if echo "$output" | grep -q "DRY RUN: lp-api download"; then
    echo "PASS: lp_download_build_artifacts"
else
    echo "FAIL: lp_download_build_artifacts"
    echo "Output: $output"
    exit 1
fi

echo "Testing lp_wait_for_build $build_link (Short Timeout)..."
# We expect this to either return 0 quickly if build is done, 
# or 1 if we timeout (we'll set a very short timeout).
lp_wait_for_build "$build_link" 1 > /dev/null 2>&1
# We just check if it runs without crashing
assert_pass "lp_wait_for_build runs"

# Restore wrapper
lp-api() {
    local args=("$@")
    local flag=$STAGING_FLAG
    local method="$1"
    local LP_API_BIN="$SCRIPT_DIR/../lp-api"
    if [ ! -f "$LP_API_BIN" ]; then
        LP_API_BIN="lp-api"
    fi
    for arg in "${args[@]}"; do
        if [[ "$arg" == "bugs/1" || "$arg" == "ubuntu" || "$arg" == "cloud-init" ]]; then
            flag=""
            break
        fi
    done
    case "$method" in
        post|patch|put|delete)
            if [[ -z "$flag" ]]; then
                echo "DRY RUN: lp-api $flag ${args[*]}"
                return 0
            fi
            ;;
    esac
    "$LP_API_BIN" $flag "${args[@]}"
}

# Section: Package Workflows
echo -e "\n--- Package Workflows ---"

# Use ubuntu project and a known package
TEST_PACKAGE="linux"
TEST_SERIES=$(lp-api get ubuntu | lp-api .current_series_link | jq -r .name)

echo "Testing lp_package_info ubuntu $TEST_SERIES $TEST_PACKAGE..."
output=$(lp_package_info ubuntu "$TEST_SERIES" "$TEST_PACKAGE" 2>&1)
if [[ $? -eq 0 ]] && echo "$output" | jq -e '.display_name // .displayname' > /dev/null; then
    echo "PASS: lp_package_info"
else
    echo "FAIL: lp_package_info"
    echo "$output"
    exit 1
fi

echo "Testing lp_package_bugs ubuntu $TEST_PACKAGE..."
output=$(lp_package_bugs ubuntu "$TEST_PACKAGE" 2>&1)
if [[ $? -eq 0 ]] && echo "$output" | jq -e '.entries != null' > /dev/null; then
    echo "PASS: lp_package_bugs"
else
    echo "FAIL: lp_package_bugs"
    echo "$output"
    exit 1
fi

echo "Testing lp_check_package_uploads ubuntu $TEST_SERIES $TEST_PACKAGE..."
output=$(lp_check_package_uploads ubuntu "$TEST_SERIES" "$TEST_PACKAGE" 2>&1)
if [[ $? -eq 0 ]] && [[ "$output" =~ ^[0-9]+$ ]]; then
    echo "PASS: lp_check_package_uploads (Count: $output)"
else
    echo "FAIL: lp_check_package_uploads"
    echo "$output"
    exit 1
fi

echo "Testing lp_get_package_set_sources ubuntu $TEST_SERIES (canonical-oem-metapackages)..."
# Syntax: lp_get_package_set_sources <distro> <series> <package-set-name>
output=$(lp_get_package_set_sources ubuntu "$TEST_SERIES" "canonical-oem-metapackages" 2>&1)
if [[ $? -eq 0 ]] && [ -n "$output" ]; then
    echo "PASS: lp_get_package_set_sources"
else
    echo "FAIL: lp_get_package_set_sources"
    echo "$output"
    exit 1
fi

# Section: PPA/Person/Team Workflows
echo -e "\n--- PPA/Person/Team Workflows ---"

TEST_OWNER="ubuntu-mozilla-security"
TEST_PPA="ppa"

echo "Testing lp_ppa_packages $TEST_OWNER $TEST_PPA..."
output=$(lp_ppa_packages "$TEST_OWNER" "$TEST_PPA" 2>&1)
if [[ $? -eq 0 ]] && [ -n "$output" ]; then
    echo "PASS: lp_ppa_packages"
else
    echo "FAIL: lp_ppa_packages"
    echo "$output"
    exit 1
fi

echo "Testing lp_ppa_copy_package (Dry Run)..."
# Usage: lp_ppa_copy_package <dest-owner> <dest-ppa> <source-name> <version> <from-archive> <to-series>
output=$(lp_ppa_copy_package "dest-owner" "dest-ppa" "pkg" "1.0" "from-archive" "to-series" 2>&1)
if echo "$output" | grep -q "DRY RUN: lp-api"; then
    echo "PASS: lp_ppa_copy_package"
else
    echo "FAIL: lp_ppa_copy_package"
    echo "Output: $output"
    exit 1
fi

echo "Testing lp_person_info fourdollars..."
output=$(lp_person_info "fourdollars" 2>&1)
if [[ $? -eq 0 ]] && echo "$output" | jq -e '.name == "fourdollars"' > /dev/null; then
    echo "PASS: lp_person_info"
else
    echo "FAIL: lp_person_info"
    echo "$output"
    exit 1
fi

echo "Testing lp_team_members ubuntu-core-dev..."
output=$(lp_team_members "ubuntu-core-dev" 2>&1)
if [[ $? -eq 0 ]] && [ -n "$output" ]; then
    echo "PASS: lp_team_members"
else
    echo "FAIL: lp_team_members"
    echo "$output"
    exit 1
fi

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