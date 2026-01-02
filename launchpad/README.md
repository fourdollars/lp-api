# Launchpad Skill for GitHub Copilot CLI

A comprehensive skill for interacting with Canonical's Launchpad platform using the `lp-api` command-line tool.

## What This Skill Does

This skill enables GitHub Copilot CLI to help you work with Launchpad (launchpad.net), providing:

- **Bug Management**: Query, search, update, and track bugs across Ubuntu and other projects
- **Build Monitoring**: Check build status, download artifacts, monitor CI/CD pipelines
- **Package Management**: Query package information, manage PPAs, sync packages
- **Team/Person Operations**: Lookup users, teams, memberships
- **Comprehensive API Coverage**: Access any Launchpad REST API resource

## When to Use This Skill

Copilot will automatically invoke this skill when you mention:

- Launchpad bugs, builds, or resources
- Ubuntu/Debian package development
- PPA management or package publishing
- Bug triage or status updates
- Build artifact downloads
- Any interaction with launchpad.net

## Installation

### Prerequisites

1. **Install lp-api tool**:
   ```bash
   go install github.com/fourdollars/lp-api@latest
   ```

2. **Verify installation**:
   ```bash
   lp-api -help
   ```

### Install the Skill

Copy this skill directory to your Copilot skills location:

```bash
# Option 1: Copy from lp-api project
cp -r /path/to/lp-api/launchpad ~/.claude/skills/

# Option 2: Create symlink (development)
ln -s /path/to/lp-api/launchpad ~/.claude/skills/launchpad
```

### Authentication Setup

The tool requires Launchpad OAuth credentials. Choose one method:

**Method 1: Environment Variable** (CI/CD, automation)
```bash
export LAUNCHPAD_TOKEN="oauth_token:oauth_secret:consumer_key"
```

**Method 2: Config File** (interactive use)
```bash
# Run any command to trigger OAuth flow
lp-api get people/+me

# Follow the prompts to authorize at launchpad.net
# Credentials saved to ~/.config/lp-api.toml
```

## What's Included

```
launchpad/
├── SKILL.md                          # Main skill definition
├── references/
│   ├── resource-paths.md             # Comprehensive API path guide
│   └── api-operations.md             # Web service operations reference
└── scripts/
    └── common-workflows.sh           # Reusable shell functions
```

## Usage Examples

Once installed, interact with Copilot naturally:

### Example 1: Bug Investigation
```
You: "Get details about Launchpad bug 1923283"

Copilot: [Uses skill to run lp-api get bugs/1923283]
```

### Example 2: Build Monitoring
```
You: "Download artifacts from the latest Ubuntu jammy build"

Copilot: [Uses skill to:
  1. Find latest build from livefs
  2. Check build status
  3. Get artifact URLs
  4. Download all files]
```

### Example 3: Bug Search
```
You: "Find all high priority Ubuntu bugs tagged with 'jammy' and 'security'"

Copilot: [Uses skill with searchTasks operation and filters]
```

### Example 4: Batch Operations
```
You: "Add the 'needs-review' tag to all bugs in the firefox project that mention 'crash'"

Copilot: [Uses skill to:
  1. Search bugs with text filter
  2. Iterate through results
  3. Update tags on each bug]
```

## Skill Resources

### Resource Path Reference

The `references/resource-paths.md` file contains comprehensive documentation on:
- People, teams, and organizations
- Bugs and bug tracking
- Projects and distributions
- Source and binary packages
- Builds and build farm
- PPAs (Personal Package Archives)
- Git repositories and branches
- Translations, specifications, questions

### API Operations Reference

The `references/api-operations.md` file documents:
- Web service operations (`ws.op=...`)
- Query parameters and filters
- Pagination and sorting
- Common workflow patterns
- Date filters, tag combinators, status values

### Workflow Scripts

The `scripts/common-workflows.sh` file provides reusable bash functions:

**Bug Workflows:**
- `lp_bug_info`, `lp_search_bugs`, `lp_count_bugs`
- `lp_bug_comment`, `lp_bug_update_tags`, `lp_bug_subscribe`

**Build Workflows:**
- `lp_latest_build`, `lp_build_status`, `lp_download_build_artifacts`
- `lp_wait_for_build`, `lp_failed_builds`

**Package Workflows:**
- `lp_package_info`, `lp_package_bugs`

**PPA Workflows:**
- `lp_ppa_packages`, `lp_ppa_copy_package`

**Person/Team Workflows:**
- `lp_person_info`, `lp_team_members`

You can source this file in your scripts:
```bash
source ~/.claude/skills/launchpad/scripts/common-workflows.sh
lp_bug_info 1923283
```

## Development & Contribution

### Project Structure

This skill is part of the `lp-api` project:
- Repository: https://github.com/fourdollars/lp-api
- Tool Documentation: See project README.md
- API Documentation: https://api.launchpad.net/devel.html

### Testing the Skill

Test skill functionality:

```bash
# Validate skill structure
python3 ~/.claude/skills/skill-creator/scripts/quick_validate.py launchpad

# Test basic operations
lp-api get people/+me
lp-api get bugs/1
lp-api get ubuntu ws.op==searchTasks ws.show==total_size
```

### Customization

You can extend this skill by:

1. **Adding new workflows** to `scripts/common-workflows.sh`
2. **Documenting additional API patterns** in reference files
3. **Creating project-specific templates** for your organization

## Troubleshooting

### "lp-api: command not found"
- Install with: `go install github.com/fourdollars/lp-api@latest`
- Ensure `$GOPATH/bin` is in your `$PATH`

### "Expired token" Error
- Remove config: `rm ~/.config/lp-api.toml`
- Re-run any command to trigger OAuth flow

### "401 Unauthorized"
- Check your OAuth credentials
- Verify you have permissions for the requested operation
- Some operations require special privileges

### Timeout Errors
- Increase timeout: `lp-api -timeout 30s get ...`
- Use `ws.show==total_size` to check result count before fetching

### Rate Limiting
- Launchpad API has rate limits
- Add delays between bulk operations
- Use pagination to avoid large single requests

## Learn More

- **lp-api Project**: https://github.com/fourdollars/lp-api
- **Launchpad API Docs**: https://api.launchpad.net/devel.html
- **Launchpad Help**: https://help.launchpad.net/
- **Ubuntu Development**: https://wiki.ubuntu.com/UbuntuDevelopment

## License

This skill inherits the license from the lp-api project. See the main project LICENSE file.

## Support

For issues with:
- **The skill itself**: File an issue in the lp-api repository
- **The lp-api tool**: https://github.com/fourdollars/lp-api/issues
- **Launchpad API**: https://answers.launchpad.net/launchpad

## Version

Skill Version: 1.0.0  
Compatible with: lp-api latest  
Last Updated: 2026-01-02
