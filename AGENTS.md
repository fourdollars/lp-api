# AGENTS.md - Developer Guide for lp-api

This guide is for AI coding agents and developers working on the lp-api project.

## Project Overview

**lp-api** is a Go CLI tool for interacting with the Launchpad API (https://api.launchpad.net/devel.html). It supports querying resources, modifying data, file uploads, and downloading build artifacts.

- **Language:** Go 1.20+
- **Type:** Single-binary CLI tool
- **Main files:** `lp-api.go`, `lp-api_test.go`
- **Dependencies:** Minimal (only `github.com/pelletier/go-toml/v2`)

## Build, Test, and Lint Commands

### Building

```bash
# Build the binary for current platform
go build -o lp-api lp-api.go

# Build with verbose output
go build -v -o lp-api lp-api.go

# Check if code compiles without producing binary
go build -o /dev/null lp-api.go
```

### Testing

```bash
# Run all tests
go test

# Run all tests with verbose output
go test -v

# Run a single test function
go test -v -run TestFunctionName

# Run tests matching a pattern
go test -v -run "Test_file.*"

# Run with race detection
go test -race

# Run with coverage
go test -cover
go test -coverprofile=coverage.out
go tool cover -html=coverage.out  # View coverage in browser

# Run integration test script
./tests/test_common_workflows.sh           # Dry run mode
./tests/test_common_workflows.sh -staging  # Real staging server
```

### Linting and Formatting

```bash
# Format code (always run before committing)
go fmt ./...
gofmt -w .

# Run go vet for static analysis
go vet ./...

# Check for suspicious constructs
go vet lp-api.go lp-api_test.go

# Ensure dependencies are tidy
go mod tidy
go mod verify
```

### Running

```bash
# Run without building
go run lp-api.go get bugs/1

# Build and run
go build && ./lp-api get bugs/1

# Enable debug output
./lp-api -debug get bugs/1

# Use staging server
./lp-api -staging get bugs/1
```

## Code Style Guidelines

### Formatting

- **MUST use `gofmt`** - All code must be formatted with `gofmt` before committing
- **Indentation:** Use tabs (handled by `gofmt`)
- **Line length:** No strict limit, let `gofmt` handle wrapping
- **Braces:** Required for all control structures (enforced by Go)

### Naming Conventions

- **Exported names:** Start with uppercase (e.g., `LaunchpadAPI`, `FileAttachment`)
- **Unexported names:** Start with lowercase (e.g., `isFileAttachment`, `extractFilePath`)
- **Use MixedCaps:** Not snake_case (e.g., `readFileContent`, not `read_file_content`)
- **No "Get" prefix:** For getters, use `Owner()` not `GetOwner()`
- **Interface names:** One-method interfaces end in `-er` (e.g., `Reader`, `Writer`)
- **Package names:** Short, concise, single-word, lowercase

### Imports

Order imports in groups (handled by `gofmt`):
1. Standard library packages (alphabetically)
2. Third-party packages (alphabetically)
3. Local packages (alphabetically)

Example from `lp-api.go`:
```go
import (
	"bytes"
	"encoding/json"
	"errors"
	"flag"
	// ... more stdlib
	"github.com/pelletier/go-toml/v2"
)
```

### Types and Structs

- Define structs with clear field names and types
- Use struct tags for serialization (e.g., `toml:"oauth_token"`)
- Example:
```go
type Credential struct {
	Key    string `toml:"oauth_consumer_key"`
	Token  string `toml:"oauth_token"`
	Secret string `toml:"oauth_token_secret"`
}
```

### Functions

- **Multiple returns:** Return `(result, error)` for operations that can fail
- **Named returns:** Use for documentation, but not required
- **Defer:** Use for cleanup (e.g., `defer resp.Body.Close()`)
- **Receiver names:** Short and consistent (e.g., `lp` for `LaunchpadAPI`)

### Error Handling

- **Always check errors explicitly** - Never use `_` to discard errors
- **Return errors** up the call stack when possible
- **Use `log.Fatal`** only in `main()` or when recovery is impossible
- **Provide context:** Wrap errors with helpful messages
- **Check specific errors:** Use `os.IsNotExist(err)`, `os.IsPermission(err)`, etc.

Example from `lp-api.go`:
```go
data, err := readFileContent(filePath)
if err != nil {
	if os.IsNotExist(err) {
		return "", fmt.Errorf("Error: File not found: %s", filePath)
	}
	if os.IsPermission(err) {
		return "", fmt.Errorf("Error: Cannot read file: permission denied")
	}
	return "", fmt.Errorf("Error: Failed to read file: %v", err)
}
```

### Control Structures

- **No parentheses** around conditions (enforced by Go syntax)
- **Braces mandatory** for all blocks
- **Initialize in if:** Use `if err := foo(); err != nil { ... }`
- **Range loops:** Use `for...range` for slices, maps, channels
- **Switch:** No fallthrough by default (use `fallthrough` if needed)

### Comments and Documentation

- **Package comment:** Every package should have a package comment
- **Exported functions:** Document with a comment starting with the function name
- **Inline comments:** Use sparingly, code should be self-documenting
- **TODO comments:** Mark incomplete work with `// TODO: description`

Example:
```go
// isFileAttachment checks if a parameter value starts with @ indicating a file path
func isFileAttachment(param string) bool {
	return strings.HasPrefix(param, "@")
}
```

### Testing

- **Test files:** Named `*_test.go` (e.g., `lp-api_test.go`)
- **Test functions:** Start with `Test` followed by name (e.g., `Test_get`, `TestIsFileAttachment`)
- **Table-driven tests:** Use structs with test cases for comprehensive testing
- **Cleanup:** Use `t.Cleanup()` for test resource cleanup
- **Subtests:** Use `t.Run()` for organizing related tests
- **Temporary files:** Use `t.TempDir()` for test file operations

Example from `lp-api_test.go`:
```go
func TestIsFileAttachment(t *testing.T) {
	tests := []struct {
		name  string
		param string
		want  bool
	}{
		{"valid file with @ prefix", "@file.log", true},
		{"no @ prefix", "file.log", false},
	}
	
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := isFileAttachment(tt.param); got != tt.want {
				t.Errorf("isFileAttachment(%q) = %v, want %v", tt.param, got, tt.want)
			}
		})
	}
}
```

## Project Structure

```
lp-api/
├── lp-api.go              # Main CLI implementation
├── lp-api_test.go         # Unit and integration tests
├── go.mod                 # Go module definition
├── go.sum                 # Dependency checksums
├── README.md              # User-facing documentation
├── LICENSE                # Apache 2.0 license
├── conductor/             # Development guidelines and specs
│   ├── workflow.md        # Development workflow
│   ├── tech-stack.md      # Technology decisions
│   └── code_styleguides/
│       └── go.md          # Go style guide summary
├── launchpad/             # Launchpad API documentation
│   ├── SKILL.md           # Comprehensive usage guide
│   ├── scripts/           # Bash helper functions
│   └── references/        # API reference docs
├── tests/                 # Integration test scripts
│   └── test_common_workflows.sh
├── specs/                 # Feature specifications
└── .github/
    └── workflows/
        └── release.yaml   # CI/CD for releases
```

## Common Development Tasks

### Adding a New Feature

1. Write failing tests first (TDD approach)
2. Implement the feature in `lp-api.go`
3. Ensure all tests pass: `go test -v`
4. Format code: `go fmt ./...`
5. Run static analysis: `go vet ./...`
6. Update documentation if needed

### Debugging

```bash
# Use -debug flag to see HTTP requests and responses
./lp-api -debug get bugs/1

# Use logging in code
log.Print("Debug message")  # Only appears with -debug flag
log.Fatal("Fatal error")    # Always appears and exits
```

### Working with File Operations

- Use `os.ReadFile()` for reading files
- Use `os.WriteFile()` for writing files
- Check specific errors: `os.IsNotExist()`, `os.IsPermission()`
- Always close file handles with `defer file.Close()`

## Key Implementation Patterns

### HTTP Requests

All API calls go through `LaunchpadAPI` methods:
- `Get()` - Retrieve resources
- `Post()` - Create or invoke operations
- `Patch()` - Update resources (JSON)
- `Put()` - Replace resources (JSON from file)
- `Delete()` - Remove resources
- `Download()` - Download files

### Authentication

OAuth 1.0a authentication using PLAINTEXT signature:
- Credentials stored in `~/.config/lp-api.toml`
- Or set via `LAUNCHPAD_TOKEN` environment variable
- Format: `token:secret:consumer_key`

### Multipart File Uploads

For file attachments (e.g., `ws.op=addAttachment`):
- Detect `@` prefix in parameters
- Read file content into memory
- Build multipart/form-data request
- Required parameter: `comment` (Launchpad API requirement)
- Optional parameters: `description`, `is_patch`, `filename`

## References

- **Effective Go:** https://go.dev/doc/effective_go
- **Go Testing:** `go help test` and `go help testfunc`
- **Launchpad API:** https://api.launchpad.net/devel.html
- **Project workflow:** `conductor/workflow.md`
- **Tech stack:** `conductor/tech-stack.md`
