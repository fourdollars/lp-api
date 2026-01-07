# Quick Installation Guide

## 1. Install lp-api Tool

Download the prebuilt binary for your platform from the [GitHub releases](https://github.com/fourdollars/lp-api/releases) page and place it in your PATH.

Alternatively, you can install using Go:
```bash
go install github.com/fourdollars/lp-api@latest
```

Verify installation:
```bash
lp-api -help
```

## 2. Install the Skill

### Option A: Copy to Skills Directory
```bash
cp -r launchpad ~/.claude/skills/
```

### Option B: Symlink (for development)
```bash
ln -s "$(pwd)/launchpad" ~/.claude/skills/launchpad
```

## 3. Set Up Authentication

### For Interactive Use:
```bash
# First use will prompt for OAuth
lp-api get people/+me
# Follow the URL to authorize
```

### For CI/CD:
```bash
export LAUNCHPAD_TOKEN="oauth_token:oauth_secret:consumer_key"
```

## 4. Verify Installation

```bash
# Test basic query
lp-api get bugs/1

# Test with skill (via Copilot)
# Ask: "Get information about Launchpad bug 1"
```

## 5. Quick Test

```bash
# Validate skill structure
python3 ~/.claude/skills/skill-creator/scripts/quick_validate.py launchpad

# Source workflow functions
source ~/.claude/skills/launchpad/scripts/common-workflows.sh

# Try a function
lp_bug_info 1
```

## Troubleshooting

**Command not found**: Add `$GOPATH/bin` to PATH
```bash
export PATH="$PATH:$(go env GOPATH)/bin"
```

**Authentication failed**: Remove and re-create credentials
```bash
rm ~/.config/lp-api.toml
lp-api get people/+me
```

## Next Steps

- Read the full README.md for detailed usage
- Browse references/ for API documentation
- Check scripts/common-workflows.sh for reusable functions
- Try example workflows with Copilot

## Quick Reference

**Get your profile:**
```bash
lp-api get people/+me
```

**Search bugs:**
```bash
lp-api get ubuntu ws.op==searchTasks tags==jammy
```

**Download build artifacts:**
```bash
lp-api get <build-path> ws.op==getFileUrls | jq -r '.[]' | xargs -I {} lp-api download {}
```

For more examples, see the main documentation.
