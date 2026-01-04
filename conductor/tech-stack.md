# Tech Stack: lp-api

## Core Technologies
- **Programming Language:** Go (version 1.20+)
- **Operating System:** Linux, macOS (Cross-platform Go support)

## Architecture
- **Type:** Single-binary CLI tool
- **Communication:** REST API with OAuth 1.0a authentication

## Libraries & Dependencies
- **Standard Library:**
  - `net/http`: Primary HTTP client for API requests.
  - `encoding/json`: Parsing and generating JSON data.
  - `flag`: CLI argument and option parsing.
  - `mime/multipart`: Handling file uploads.
- **Third-Party:**
  - `github.com/pelletier/go-toml/v2`: Parsing configuration files (e.g., `~/.config/lp-api.toml`).

## Infrastructure & External Services
- **API:** Launchpad API (https://api.launchpad.net/devel.html)
- **CI/CD:** GitHub Actions (defined in `.github/workflows/release.yaml`)
