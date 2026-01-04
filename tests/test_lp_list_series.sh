#!/bin/bash
# Test script for lp_list_series

# Source the common workflows
source "$(dirname "$0")/../launchpad/scripts/common-workflows.sh"

# Test 1: Check if function exists (this should fail initially)
if ! command -v lp_list_series &> /dev/null; then
    echo "FAIL: lp_list_series function not found"
    exit 1
fi

echo "PASS: lp_list_series function exists"
