# Specification: Test and Fix Common Workflows

## 1. Overview
The goal of this track is to validate, fix, or remove the shell functions defined in `launchpad/scripts/common-workflows.sh`. This script contains reusable workflows for interacting with the Launchpad API. Additionally, we will remove the deprecated standalone script `launchpad/scripts/list_series.sh` and consolidate testing by renaming `tests/test_lp_list_series.sh` to `tests/test_common_workflows.sh`, expanding it to cover all functions.

## 2. Functional Requirements

### 2.1 Testing Scope
- **Target File:** `launchpad/scripts/common-workflows.sh`
- **Coverage:** Every function defined in the script must be tested or explicitly marked as skipped (e.g., for safety reasons).
- **Consolidation:** Rename `tests/test_lp_list_series.sh` to `tests/test_common_workflows.sh` and use it as the main test suite for all functions in `common-workflows.sh`.

### 2.2 Test Implementation
- **Framework:** Custom shell script assertions.
- **Structure:**
  - Source `launchpad/scripts/common-workflows.sh`.
  - Test each function category: Bug Workflows, Build Workflows, Package Workflows, etc.
  - Assertions should check for non-zero exit codes on valid queries and verify that output contains expected keywords or JSON structures.
- **API Interaction:**
  - **Read Operations:** Use the production Launchpad API for GET requests (e.g., querying public bugs, projects, or people).
  - **Write Operations:** For safety, functions that perform POST, PATCH, or DELETE (like `lp_bug_comment` or `lp_bug_update_tags`) will NOT be executed against production during automated tests. Their implementation will be reviewed and manually verified if possible.

### 2.3 Cleanup and Removal
- **Deprecation:** **Delete `launchpad/scripts/list_series.sh`**.
- **Refactoring:** Fix logic bugs discovered during testing in `common-workflows.sh`.
- **Removal:** Remove functions from `common-workflows.sh` that are:
  - Confirmed as dead code.
  - Non-functional and low-value.
  - Redundant with the Go binary's core capabilities.

## 3. Non-Functional Requirements
- **Maintainability:** Ensure the test script is easy to run and provides clear pass/fail output for each function.
- **Cleanliness:** Remove any "todo" or "example" functions from `common-workflows.sh` that do not provide clear value to the project.

## 4. Acceptance Criteria
- [ ] `tests/test_lp_list_series.sh` is renamed to `tests/test_common_workflows.sh`.
- [ ] `tests/test_common_workflows.sh` contains test cases for all functions in `common-workflows.sh`.
- [ ] `launchpad/scripts/list_series.sh` is deleted.
- [ ] All remaining functions in `common-workflows.sh` pass their tests.
- [ ] Broken or unnecessary functions are removed from `common-workflows.sh`.

## 5. Out of Scope
- Mocking the Launchpad API (using real production GETs instead).
- Changes to the Go source code.
