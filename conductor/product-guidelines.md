# Product Guidelines: lp-api

## Design Principles
- **UNIX Philosophy:** Do one thing well. Silent on success, explicit on error.
- **Pipe-Friendly:** Output JSON by default or raw data when requested to facilitate chaining with tools like `jq`.
- **Stateless:** Each command should be independent, relying on arguments and configuration rather than session state.

## CLI UX Guidelines
- **Output:**
    - Standard Output (stdout): Pure JSON or requested data only.
    - Standard Error (stderr): Progress indicators, debug logs, and error messages.
- **Verbosity:** Support `-debug` or `-verbose` flags for troubleshooting OAuth and API calls.
- **Error Handling:** Exit with non-zero codes for API failures or network issues.

## Branding
- **Name:** `lp-api` (lowercase, hyphenated).
- **Identity:** A "Swiss Army Knife" for Launchpad power users.

## Coding Standards (General)
- **Simplicity:** Prefer readable, idiomatic Go code over complex abstractions.
- **Documentation:** All exported functions and complex logic must have comments.
