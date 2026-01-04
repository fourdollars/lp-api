#!/bin/bash
# Test script for lp_list_series

# Source the common workflows
# We use an absolute path or relative to script to ensure it's found
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../launchpad/scripts/common-workflows.sh"

# Mock/Fake lp-api check if necessary, but here we expect it to fail 
# because the function itself is missing from the sourced file.

echo "--- Test 1: Function Existence ---"
if ! command -v lp_list_series &> /dev/null; then
    echo "FAIL: lp_list_series function not found"
    # We continue to show other failures
else
    echo "PASS: lp_list_series function exists"
fi

echo -e "\n--- Test 2: Default Project (ubuntu) ---"
# This will fail with "command not found" if the function is missing
output=$(lp_list_series 2>&1)
if [[ $? -ne 0 ]]; then
    echo "FAIL: lp_list_series failed to execute"
    echo "Error: $output"
else
    echo "PASS: lp_list_series executed"
    # Check for headers
    if echo "$output" | grep -q "Name" && echo "$output" | grep -q "Status" && echo "$output" | grep -q "Display Name"; then
        echo "PASS: Found expected headers"
    else
        echo "FAIL: Missing expected headers in output"
        echo "Output was: $output"
    fi
fi

echo -e "\n--- Test 3: Specific Project (cloud-init) ---"
output=$(lp_list_series cloud-init 2>&1)
if [[ $? -ne 0 ]]; then
    echo "FAIL: lp_list_series cloud-init failed to execute"
else
    echo "PASS: lp_list_series cloud-init executed"
fi