# Launchpad Skill for GitHub Copilot CLI & Gemini CLI

A comprehensive skill for interacting with Canonical's Launchpad platform using the `lp-api` command-line tool.

## What This Skill Does

This skill enables AI assistants (GitHub Copilot CLI / Claude Code, Gemini CLI) to help you work with Launchpad (launchpad.net), providing:

- **Bug Management**: Query, search, update, and track bugs across Ubuntu and other projects
- **Build Monitoring**: Check build status, download artifacts, monitor CI/CD pipelines
- **Package Management**: Query package information, manage PPAs, sync packages
- **Team/Person Operations**: Lookup users, teams, memberships
- **Comprehensive API Coverage**: Access any Launchpad REST API resource

## When to Use This Skill

The assistant will automatically invoke this skill when you mention:

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

### Option A: Install for Gemini CLI

Navigate to the directory containing this skill and run:

```bash
gemini extensions install .
```

### Option B: Install for GitHub Copilot CLI (Claude)

Copy this skill directory to your Copilot skills location:

```bash
# Copy from lp-api project
cp -r /path/to/lp-api/launchpad ~/.claude/skills/

# OR Create symlink (development)
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
├── SKILL.md                          # Claude Code skill definition
├── GEMINI.md                         # Gemini CLI extension definition
├── gemini-extension.json             # Gemini CLI manifest
├── references/
│   ├── archive.md                    # Archives and PPAs
│   ├── basics.md                     # API concepts, pagination, miscellaneous
│   ├── bugs.md                       # Bug tracking
│   ├── git.md                        # Git repositories and recipes
│   ├── livefs.md                     # LiveFS build monitoring
│   ├── package-sets.md               # Package set management
│   ├── people.md                     # People, teams, and memberships
│   ├── project.md                    # Projects, milestones, and releases
│   └── series.md                     # Distribution series
└── scripts/
    └── common-workflows.sh           # Reusable shell functions
```

## Usage Examples

Once installed, interact with your assistant naturally:

### Example 1: Bug Investigation
```
You: "Get details about Launchpad bug 1"

Assistant: [Uses skill to run lp-api get bugs/1]
```

### Example 2: Build Monitoring
```
You: "Download artifacts from the latest Ubuntu jammy build"

Assistant: [Uses skill to:
  1. Find latest build from livefs
  2. Check build status
  3. Get artifact URLs
  4. Download all files]
```

### Example 3: Bug Search
```
You: "Find all high priority Ubuntu bugs tagged with 'jammy' and 'security'"

Assistant: [Uses skill with searchTasks operation and filters]
```

### Example 4: Batch Operations
```
You: "Add the 'needs-review' tag to all bugs in the firefox project that mention 'crash'"

Assistant: [Uses skill to:
  1. Search bugs with text filter
  2. Iterate through results
  3. Update tags on each bug]
```

## Skill Resources

### Modular Reference Guides

The `references/` directory contains topic-specific documentation:

- **archive.md**: Archives, PPAs, copying/syncing packages.
- **basics.md**: URL structure, pagination, date filters, sorting, miscellaneous resources (Translations, Specs).
- **bugs.md**: Searching, creating, modifying bugs, comments, and attachments.
- **git.md**: Hosting Git repositories and building with Recipes.
- **livefs.md**: Monitoring and managing LiveFS builds.
- **package-sets.md**: Listing and querying package sets and sources.
- **people.md**: Managing users, teams, and memberships.
- **project.md**: Managing projects, milestones, and releases.
- **series.md**: Working with distribution series (e.g., focal, jammy).

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

## Development & Contribution

### Project Structure

This skill is part of the `lp-api` project:
- Repository: https://github.com/fourdollars/lp-api
- Tool Documentation: See project README.md
- API Documentation: https://api.launchpad.net/devel.html

### Testing the Skill

Test skill functionality:

```bash
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

Skill Version: 1.1.0
Compatible with: lp-api latest
Last Updated: 2026-01-04
