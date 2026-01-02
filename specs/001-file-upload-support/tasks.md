# Implementation Tasks: File Upload Support

## Overview
This document outlines all implementation tasks for adding file upload/attachment support to lp-api. Tasks are organized by phase and include dependencies and execution order.

## Task Execution Rules
- **Sequential tasks**: Execute in order within each phase
- **Parallel tasks [P]**: Can be executed concurrently (marked with [P] suffix)
- **Dependencies**: Complete prior phases before moving to next
- **Test-first**: Write tests before implementations where applicable

---

## Phase 1: Setup & Infrastructure

### Task 1.1: Create file upload helper module [P]
**ID**: SETUP-001  
**Description**: Create `launchpad/upload.go` with foundational types and helper functions for file upload operations.  
**Files**: `lp-api.go`  
**Dependencies**: None  
**Acceptance**:
- [X] File exists with package declaration
- [X] Basic types defined: FileAttachment struct with fields (Path, Filename, ContentType, Data)
- [X] Placeholder functions: DetectContentType(), ReadFileContent()

### Task 1.2: Add unit test file for upload module [P]
**ID**: SETUP-002  
**Description**: Create `launchpad/upload_test.go` for testing upload functionality.  
**Files**: `lp-api_test.go`  
**Dependencies**: None  
**Acceptance**:
- [X] Test file exists with package declaration
- [X] Imports testing framework
- [X] Placeholder test functions defined

---

## Phase 2: Core File Handling Implementation

### Task 2.1: Implement file path detection with @ prefix
**ID**: CORE-001  
**Description**: Add function to detect `@filepath` syntax in parameter values and extract file paths.  
**Files**: `lp-api.go`  
**Dependencies**: SETUP-001  
**Acceptance**:
- [X] Function `isFileAttachment(param string) bool` returns true for "@/path/file"
- [X] Function `extractFilePath(param string) string` extracts path from "@/path/file"
- [X] Handles edge cases: no @, multiple @, empty string

### Task 2.2: Write tests for file path detection
**ID**: TEST-001  
**Description**: Add comprehensive tests for @ prefix detection logic.  
**Files**: `lp-api_test.go`  
**Dependencies**: CORE-001  
**Acceptance**:
- [X] Test valid cases: `@file.log`, `@/absolute/path.txt`, `@../relative/file.png`
- [X] Test invalid cases: `file.log` (no @), empty string, `@` only
- [X] Test edge cases: `@@file.log`, `@file with spaces.log`
- [X] All tests pass

### Task 2.3: Implement file reading functionality
**ID**: CORE-002  
**Description**: Implement function to read file content from disk into memory.  
**Files**: `lp-api.go`  
**Dependencies**: CORE-001  
**Acceptance**:
- [X] Function `readFileContent(filepath string) ([]byte, error)` reads file
- [X] Returns error for non-existent files
- [X] Returns error for permission denied
- [X] Reads binary and text files correctly

### Task 2.4: Write tests for file reading
**ID**: TEST-002  
**Description**: Add tests for file reading with various scenarios.  
**Files**: `lp-api_test.go`  
**Dependencies**: CORE-002  
**Acceptance**:
- [X] Test reading valid text file
- [X] Test reading binary file (create small test file)
- [X] Test file not found error
- [X] Test permission denied error (if possible in test env)
- [X] All tests pass

### Task 2.5: Implement MIME type detection
**ID**: CORE-003  
**Description**: Add function to detect MIME type from file extension using stdlib mime package.  
**Files**: `lp-api.go`  
**Dependencies**: CORE-001  
**Acceptance**:
- [X] Function `detectContentType(filepath string) string` returns MIME type
- [X] Handles common extensions: .log → text/plain, .png → image/png, .json → application/json
- [X] Falls back to application/octet-stream for unknown extensions
- [X] Case-insensitive extension matching

### Task 2.6: Write tests for MIME type detection
**ID**: TEST-003  
**Description**: Add tests for MIME type detection logic.  
**Files**: `lp-api_test.go`  
**Dependencies**: CORE-003  
**Acceptance**:
- [X] Test known types: .log, .txt, .png, .jpg, .json, .yaml, .tar.gz
- [X] Test unknown extension returns octet-stream
- [X] Test case insensitivity: .LOG vs .log
- [X] All tests pass

---

## Phase 3: Multipart Request Construction

### Task 3.1: Implement multipart/form-data body builder
**ID**: CORE-004  
**Description**: Create function to construct multipart/form-data request body with file content and form fields.  
**Files**: `lp-api.go`  
**Dependencies**: CORE-002, CORE-003  
**Acceptance**:
- [X] Function `buildMultipartBody(attachment FileAttachment, params map[string]string) (*bytes.Buffer, string, error)` creates body
- [X] Returns buffer with multipart data and boundary string
- [X] Includes file data with correct Content-Disposition and Content-Type headers
- [X] Includes form fields (ws.op, description, comment, etc.)
- [X] Uses mime/multipart package from stdlib

### Task 3.2: Write tests for multipart body construction
**ID**: TEST-004  
**Description**: Add tests to verify multipart body structure and content.  
**Files**: `lp-api_test.go`  
**Dependencies**: CORE-004  
**Acceptance**:
- [X] Test body contains proper multipart boundaries
- [X] Test file data is included with correct filename
- [X] Test form fields are included
- [X] Test Content-Type headers are set correctly
- [X] Parse and validate multipart structure in tests
- [X] All tests pass

---

## Phase 4: Integration with lp-api Main CLI

### Task 4.1: Detect file attachment in Post method
**ID**: INTEGRATE-001  
**Description**: Modify `Post()` method in lp-api.go to detect `attachment=@filepath` parameter.  
**Files**: `lp-api.go`  
**Dependencies**: CORE-001  
**Acceptance**:
- [X] In Post() method, check each arg for attachment=@ prefix
- [X] Extract file parameter and path when detected
- [X] Store flag indicating multipart upload needed
- [X] Non-file parameters handled as before

### Task 4.2: Integrate multipart upload in Post method
**ID**: INTEGRATE-002  
**Description**: When file attachment detected, use multipart builder instead of form encoding.  
**Files**: `lp-api.go`  
**Dependencies**: INTEGRATE-001, CORE-004  
**Acceptance**:
- [X] When attachment detected, call buildMultipartBody()
- [X] Set Content-Type header to multipart/form-data with boundary
- [X] Send multipart body in POST request
- [X] Fall back to regular form encoding for non-file requests
- [X] Maintain backward compatibility with existing POST usage

### Task 4.3: Add error handling for file operations
**ID**: INTEGRATE-003  
**Description**: Add comprehensive error handling for file upload scenarios.  
**Files**: `lp-api.go`  
**Dependencies**: INTEGRATE-002  
**Acceptance**:
- [X] Check file exists before reading (clear error message)
- [X] Handle permission denied errors (clear error message)
- [X] Handle file read errors with context
- [X] Propagate API errors with original messages
- [X] Error messages go to stderr, exit code 1 on failure

---

## Phase 5: Testing & Validation

### Task 5.1: Add integration test helper [P]
**ID**: TEST-005  
**Description**: Create test helper to generate temporary test files for integration tests.  
**Files**: `lp-api_test.go`  
**Dependencies**: None  
**Acceptance**:
- Helper function creates temp text file with content
- Helper function creates temp binary file
- Helper cleans up files after test
- Returns file path for use in tests

### Task 5.2: Add end-to-end test for file upload flow
**ID**: TEST-006  
**Description**: Create integration test that exercises the full file upload flow (mock API).  
**Files**: `lp-api_test.go`  
**Dependencies**: TEST-005, INTEGRATE-003  
**Acceptance**:
- Test creates temp file
- Test calls Post() with attachment=@tempfile
- Test verifies multipart body is constructed correctly
- Test mocks HTTP response
- Test verifies success path
- Test verifies error handling (file not found)
- All tests pass

### Task 5.3: Update existing tests for backward compatibility
**ID**: TEST-007  
**Description**: Ensure existing Post() tests still pass after file upload integration.  
**Files**: `lp-api_test.go`  
**Dependencies**: INTEGRATE-002  
**Acceptance**:
- [X] Run existing test suite
- [X] Verify all existing POST tests pass
- [X] Verify GET, PATCH, PUT, DELETE methods unaffected
- [X] No regressions introduced

---

## Phase 6: Documentation & Polish

### Task 6.1: Add code comments and documentation [P]
**ID**: DOC-001  
**Description**: Add godoc-style comments to all exported functions in upload module.  
**Files**: `launchpad/upload.go`  
**Dependencies**: CORE-004  
**Acceptance**:
- Every exported function has doc comment
- Comments explain parameters and return values
- Comments include usage examples where helpful
- Package-level documentation added

### Task 6.2: Update README with file upload examples [P]
**ID**: DOC-002  
**Description**: Add file upload usage examples to main README.md.  
**Files**: `README.md`  
**Dependencies**: None  
**Acceptance**:
- [X] Add "File Upload" section to README
- [X] Include basic example: attaching log file to bug
- [X] Include example with description parameter
- [X] Link to quickstart.md for more examples
- [X] Show error handling example

### Task 6.3: Verify .gitignore coverage [P]
**ID**: POLISH-001  
**Description**: Ensure .gitignore has proper patterns for Go projects.  
**Files**: `.gitignore`  
**Dependencies**: None  
**Acceptance**:
- [X] Check .gitignore contains Go patterns: `*.test`, `*.out`, `*.exe`
- [X] Add any missing patterns if needed
- [X] No test artifacts or binaries committed

### Task 6.4: Verify .dockerignore coverage [P]
**ID**: POLISH-002  
**Description**: Ensure .dockerignore excludes unnecessary files from Docker builds.  
**Files**: `.dockerignore`  
**Dependencies**: None  
**Acceptance**:
- Check .dockerignore exists and contains: `.git/`, `*.test`, `.vscode/`, `specs/`, `README.md`
- Add missing patterns if needed

---

## Phase 7: Final Validation

### Task 7.1: Run full test suite
**ID**: VALIDATE-001  
**Description**: Execute all tests to ensure implementation is correct and complete.  
**Files**: N/A  
**Command**: `go test ./... -v`  
**Dependencies**: TEST-007  
**Acceptance**:
- [X] All unit tests pass
- [X] All integration tests pass
- [X] No test failures or panics
- [X] Coverage reasonable for new code

### Task 7.2: Build and verify binary
**ID**: VALIDATE-002  
**Description**: Build lp-api binary and verify it runs without errors.  
**Files**: N/A  
**Command**: `go build -o lp-api lp-api.go`  
**Dependencies**: VALIDATE-001  
**Acceptance**:
- [X] Build completes without errors
- [X] Binary runs: `./lp-api --help` shows usage
- [X] No obvious runtime errors

### Task 7.3: Manual smoke test with test file
**ID**: VALIDATE-003  
**Description**: Manually test file attachment command with a real test file (no actual API call).  
**Files**: N/A  
**Dependencies**: VALIDATE-002  
**Acceptance**:
- [X] Create test file: `echo "test" > /tmp/test.log`
- [X] Verify command parsing works: output shows file would be attached
- [X] Verify error handling: test with non-existent file shows clear error
- [X] Command structure matches documented examples

---

## Summary

**Total Tasks**: 29  
**Phases**: 7  
**Parallel Opportunities**: 6 tasks can be done in parallel with others  
**Critical Path**: SETUP → CORE → INTEGRATE → TEST → VALIDATE

**Estimated Implementation Time**:
- Phase 1 (Setup): ~30 minutes
- Phase 2 (Core): ~2 hours
- Phase 3 (Multipart): ~1.5 hours  
- Phase 4 (Integration): ~2 hours
- Phase 5 (Testing): ~2 hours
- Phase 6 (Documentation): ~1 hour
- Phase 7 (Validation): ~30 minutes

**Total**: ~9.5 hours for full implementation

## Notes
- All file operations use stdlib packages (mime, mime/multipart, os, io)
- No external dependencies needed beyond existing go-toml
- Maintains backward compatibility with existing CLI usage
- Follows existing code patterns and conventions in lp-api.go
