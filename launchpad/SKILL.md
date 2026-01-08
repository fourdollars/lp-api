---
name: launchpad
description: Interact with Canonical's Launchpad platform (launchpad.net) using the lp-api CLI tool. Use when working with Ubuntu/Debian packages, bugs, builds, people, projects, or any Launchpad resources. Triggered by mentions of Launchpad, Ubuntu development, package builds, or bug tracking on launchpad.net.
metadata:
  version: "1.1.3"
---

# Launchpad

## Overview

This skill enables interaction with Canonical's Launchpad platform (https://launchpad.net) through the `lp-api` command-line tool. It provides full CRUD capabilities (Create, Read, Update, Delete) for querying and managing bugs, people, projects, builds, and other Launchpad resources via the REST API at https://api.launchpad.net/devel.html.

**Important Note:** All `lp-api` commands return JSON responses except using with ws.show==total_size, or using download and pipe subcommands. Parse these outputs to extract meaningful information.

## Installation & Troubleshooting

If `lp-api` is not found, use the GitHub API to find and download the correct binary for your system.

**1. Find download URL:**
```bash
# Get the browser_download_url for your OS (linux/darwin/windows) and Architecture (amd64/arm64)
# Example for Linux AMD64:
curl -s https://api.github.com/repos/fourdollars/lp-api/releases | \
  jq -r '.[0].assets[] | select(.name | endswith("linux-amd64.tar.gz")) | .browser_download_url'
```

**2. Download and Install:**
```bash
curl -L -o lp-api.tar.gz <URL>
tar -xzf lp-api.tar.gz
chmod +x lp-api
mkdir -p bin
mv lp-api bin/
export PATH=$PWD/bin:$PATH
```

## Authentication

The tool handles OAuth authentication automatically:

1. **Environment Variable** (preferred for CI/CD):
   ```bash
   export LAUNCHPAD_TOKEN="oauth_token:oauth_secret:consumer_key"
   ```

2. **Config File** (for interactive use):
   - Stored at `.lp-api.toml` in the current directory (recommended)
   - Use `-conf .lp-api.toml` to specify the location
   - Created automatically on first run via OAuth flow
   - User prompted to authorize at launchpad.net

## Resources

Refer to the documentation in `references/` for detailed usage, patterns, and workflows:

- **basics.md**: **START HERE**. CLI usage, core operations (GET/PATCH/POST), URL structure.
- **workflow.md**: Common workflows combining multiple operations (Bug triage, Batch updates, Build monitoring).
- **bugs.md**: Comprehensive guide to bug tracking, searching, and attachments.
- **git.md**: Guide to Git repositories, recipes, and merge proposal reviews.
- **livefs.md**: Guide to monitoring and managing LiveFS (ISO) builds.
- **archive.md**: Guide to working with archives (PPAs) and publishing.
- **package-sets.md**: Guide to managing package sets.
- **people.md**: Guide to managing people, teams, and memberships.
- **project.md**: Guide to managing projects, milestones, and releases.
- **series.md**: Guide to working with Launchpad series (distro releases).
