# Plan: Add `lp_list_series` to `common-workflows.sh`

## Phase 1: Preparation and Testing (TDD Red Phase) [checkpoint: 591314f]
- [x] Task: Create a reproduction/test script `tests/test_lp_list_series.sh` to verify the new function. d7d900a
- [x] Task: Write failing tests in `tests/test_lp_list_series.sh` that attempt to call `lp_list_series` and verify the tabular output format. 2c79618
- [x] Task: Confirm tests fail as the function does not yet exist. 89d4359
- [x] Task: Conductor - User Manual Verification 'Phase 1: Preparation and Testing' (Protocol in workflow.md)

## Phase 2: Implementation (TDD Green Phase)
- [x] Task: Implement the `lp_list_series` function in `launchpad/scripts/common-workflows.sh`. 0318419
    - [x] Handle default `project="ubuntu"`.
    - [x] Fetch project data using `lp-api get`.
    - [x] Follow `series_collection_link`.
    - [x] Use `jq` to format the entries into a table (Name, Status, Display Name, Web Link).
- [ ] Task: Run the test script `tests/test_lp_list_series.sh` and verify that all tests now pass.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Implementation' (Protocol in workflow.md)

## Phase 3: Refinement and Documentation
- [ ] Task: Refactor the `lp_list_series` implementation for clarity and error handling (e.g., check if `lp-api` is available).
- [ ] Task: Update the usage information at the end of `common-workflows.sh` to include `lp_list_series`.
- [ ] Task: Verify final output matches the project's code style guidelines.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Refinement and Documentation' (Protocol in workflow.md)
