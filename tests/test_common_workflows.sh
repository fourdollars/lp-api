#!/bin/bash
# Test suite for common-workflows.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../launchpad/scripts/common-workflows.sh"

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
echo "TODO: Add bug workflow tests"

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
if command -v lp_list_series &> /dev/null; then
    echo "PASS: lp_list_series exists"
    
    # Test default
    output=$(lp_list_series 2>&1)
    if [ $? -eq 0 ] && echo "$output" | grep -q "Series"; then
        echo "PASS: lp_list_series (default) runs and has headers"
    else
        echo "FAIL: lp_list_series (default) failed"
        echo "$output"
        exit 1
    fi
    
    # Test specific
    lp_list_series cloud-init > /dev/null 2>&1
    assert_pass "lp_list_series cloud-init runs"
else
    echo "FAIL: lp_list_series not found"
    exit 1
fi

echo -e "\n=== Test Suite Complete ==="
