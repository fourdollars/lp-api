# Implementation Plan: Test and Fix Common Workflows

## Phase 1: Setup and Consolidation [checkpoint: 12e2f60]
Prepare the testing environment and remove deprecated files.

- [x] Task: Rename `tests/test_lp_list_series.sh` to `tests/test_common_workflows.sh` 002f479
- [x] Task: Delete deprecated `launchpad/scripts/list_series.sh` 2c5a6f1
- [x] Task: Update `tests/test_common_workflows.sh` to source the correct path and initialize a basic test structure for all categories 8c99fc5
- [x] Task: Conductor - User Manual Verification 'Phase 1: Setup and Consolidation' (Protocol in workflow.md) 12e2f60

## Phase 2: Bug Workflow Verification [checkpoint: 59615a7]
Verify and repair all functions related to bug management.

- [x] Task: Implement read-only tests for `lp_bug_info` (basic fetch), `lp_search_bugs` (querying), `lp_count_bugs` (aggregation), `lp_bug_has_tag`, `lp_bug_task_status`, and `lp_get_bug_tasks`.
- [x] Task: Review and verify write operations (dry-run or manual check logic): `lp_bug_comment`, `lp_bug_update_tags`, `lp_bug_subscribe`.
- [x] Task: Conductor - User Manual Verification 'Phase 2: Bug Workflow Verification' (Protocol in workflow.md) 59615a7

## Phase 3: Build, Package, and PPA Verification
Verify and repair all functions for builds, packages, PPAs, and teams.

- [x] Task: Implement tests for Build Workflows: `lp_latest_build`, `lp_build_status`, `lp_download_build_artifacts`, `lp_failed_builds`, and `lp_wait_for_build` (mocking or short timeout).
- [x] Task: Implement tests for Package Workflows: `lp_package_info`, `lp_package_bugs`, `lp_check_package_uploads`, `lp_get_package_set_sources`.
- [x] Task: Implement tests for PPA and Person/Team Workflows: `lp_ppa_packages`, `lp_ppa_copy_package` (write op check), `lp_person_info`, `lp_team_members`.
- [x] Task: Conductor - User Manual Verification 'Phase 3: Build, Package, and PPA Verification' (Protocol in workflow.md)

## Phase 4: Utility and Helper Verification
Verify general utility functions and final cleanup.

- [x] Task: Implement tests for Utility Functions: `lp_follow_link`, `lp_get_field`, `lp_list_series`, `lp_pretty`, `lp_wadl`, `lp_extract_web_links`, `lp_show_links`, and `lp_paginate_all`.
- [x] Task: Review all "Example Workflows" in the script and remove/update as needed.
- [x] Task: Update the "Usage" help message in `common-workflows.sh` to reflect the verified function list.
- [x] Task: Run the full `tests/test_common_workflows.sh` suite to ensure 100% coverage of remaining functions.
- [x] Task: Conductor - User Manual Verification 'Phase 4: Utility and Helper Verification' (Protocol in workflow.md) 5f99a0c
