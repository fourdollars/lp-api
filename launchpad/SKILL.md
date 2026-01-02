---
name: launchpad
description: Interact with Canonical's Launchpad platform (launchpad.net) using the lp-api CLI tool. Use when working with Ubuntu/Debian packages, bugs, builds, people, projects, or any Launchpad resources. Triggered by mentions of Launchpad, Ubuntu development, package builds, or bug tracking on launchpad.net.
---

# Launchpad

## Overview

This skill enables interaction with Canonical's Launchpad platform (https://launchpad.net) through the `lp-api` command-line tool. It provides capabilities for querying and managing bugs, people, projects, builds, and other Launchpad resources via the REST API at https://api.launchpad.net/devel.html.

## Core Capabilities

### 1. Resource Querying (GET)

Query any Launchpad resource by its path. The API follows REST principles with predictable paths.

**Basic Pattern:**
```bash
lp-api get <resource-path> [query-parameters]
```

**Common Examples:**

```bash
# Get your own Launchpad account
lp-api get people/+me

# Get a specific bug
lp-api get bugs/1

# Get a person's profile
lp-api get ~username

# Get Ubuntu project info
lp-api get ubuntu

# Get a specific build
lp-api get ~ubuntu-cdimage/+livefs/ubuntu/jammy/ubuntu
```

**Query Parameters:**
Use `key==value` syntax for query parameters:

```bash
# Search Ubuntu bugs with multiple tags
lp-api get ubuntu ws.op==searchTasks tags==focal tags==jammy tags_combinator==All

# Get total count only
lp-api get ubuntu ws.op==searchTasks ws.show==total_size

# Filter by status
lp-api get ubuntu/+bugs status==New
```

### 2. Resource Modification (PATCH)

Update existing resources using JSON data with `:=` syntax.

**Basic Pattern:**
```bash
lp-api patch <resource-path> field:='json-value'
```

**Examples:**

```bash
# Update bug tags
lp-api patch bugs/123456 tags:='["focal","jammy"]'

# Clear tags
lp-api patch bugs/123456 tags:='[]'

# Update bug status
lp-api patch bugs/123456 status:='"Fix Released"'

# Update importance
lp-api patch bugs/123456 importance:='"High"'
```

### 3. Resource Creation (POST)

Create new resources or invoke operations using form data.

**Basic Pattern:**
```bash
lp-api post <resource-path> ws.op=<operation> param=value
```

**Examples:**

```bash
# Add comment to bug
lp-api post bugs/123456 ws.op=newMessage content="This is a comment"

# Subscribe to bug
lp-api post bugs/123456 ws.op=subscribe

# Create a new bug task
lp-api post ubuntu/+bugs ws.op=createBugTask title="Bug title" description="Details"
```

### 4. Resource Replacement (PUT)

Replace entire resource with JSON file content.

**Basic Pattern:**
```bash
lp-api put <resource-path> <json-file>
```

**Example:**
```bash
# Update bug with complete JSON definition
lp-api put bugs/123456 bug-update.json
```

### 5. Resource Deletion (DELETE)

Remove resources when permissions allow.

**Basic Pattern:**
```bash
lp-api delete <resource-path>
```

### 6. Piping Resource Links

Extract and follow resource links from JSON output using the `.fieldname` syntax.

**Basic Pattern:**
```bash
lp-api get <resource> | lp-api .<link-field>
```

**Examples:**

```bash
# Get latest build from livefs
BUILD=$(lp-api get ~ubuntu-cdimage/+livefs/ubuntu/jammy/ubuntu | lp-api .builds_collection_link | jq -r '.entries | .[0] | .web_link')

# Follow self_link from search results
lp-api get ubuntu ws.op==searchTasks | lp-api .self_link
```

### 7. File Downloads

Download artifacts from Launchpad builds.

**Basic Pattern:**
```bash
lp-api download <file-url>
```

**Complete Workflow Example:**

```bash
# Get the latest build for Ubuntu jammy
BUILD=$(lp-api get ~ubuntu-cdimage/+livefs/ubuntu/jammy/ubuntu | \
        lp-api .builds_collection_link | \
        jq -r '.entries | .[0] | .web_link')

echo "Latest build: $BUILD"

# Download all artifacts from that build
while read -r LINK; do 
  lp-api download "$LINK"
done < <(lp-api get "~${BUILD//*~/}" ws.op==getFileUrls | jq -r .[])
```

## Common Workflows

### Workflow 1: Bug Investigation

```bash
# 1. Get bug details
lp-api get bugs/1923283 | jq .

# 2. Get bug tasks (which projects/packages are affected)
lp-api get bugs/1923283 | lp-api .bug_tasks_collection_link | jq .

# 3. Get bug messages/comments
lp-api get bugs/1923283 | lp-api .messages_collection_link | jq .

# 4. Check bug subscriptions
lp-api get bugs/1923283 | lp-api .subscriptions_collection_link | jq .
```

### Workflow 2: Package Build Monitoring

```bash
# 1. Find the livefs for a release
lp-api get ~ubuntu-cdimage/+livefs/ubuntu/jammy/ubuntu

# 2. Get recent builds
lp-api get ~ubuntu-cdimage/+livefs/ubuntu/jammy/ubuntu | \
  lp-api .builds_collection_link

# 3. Check specific build status
lp-api get <build-resource-path> | jq '.buildstate'

# 4. Download build artifacts when ready
lp-api get <build-resource-path> ws.op==getFileUrls | \
  jq -r '.[]' | \
  xargs -I {} lp-api download {}
```

### Workflow 3: Batch Bug Updates

```bash
# Search for bugs to update
BUGS=$(lp-api get ubuntu ws.op==searchTasks tags==needs-update | \
       jq -r '.entries[].bug_link')

# Update each bug
for BUG in $BUGS; do
  lp-api patch "$BUG" tags:='["updated","focal"]'
done
```

## Authentication

The tool handles OAuth authentication automatically:

1. **Environment Variable** (preferred for CI/CD):
   ```bash
   export LAUNCHPAD_TOKEN="oauth_token:oauth_secret:consumer_key"
   ```

2. **Config File** (for interactive use):
   - Stored at `~/.config/lp-api.toml`
   - Created automatically on first run via OAuth flow
   - User prompted to authorize at launchpad.net

3. **Custom Config Path**:
   ```bash
   lp-api -conf /path/to/config.toml get people/+me
   ```

## Command Options

```bash
-conf string      # Config file path (default: ~/.config/lp-api.toml)
-debug           # Show debug messages including OAuth headers
-help            # Show help message
-key string      # OAuth consumer key (default: "System-wide: golang...")
-output string   # Save output to file instead of stdout
-staging         # Use Launchpad staging server (api.staging.launchpad.net)
-timeout duration # API request timeout (default: 10s)
```

**Examples:**

```bash
# Debug mode to see full OAuth flow
lp-api -debug get people/+me

# Save to file
lp-api -output result.json get bugs/1

# Use staging server for testing
lp-api -staging get bugs/1923283

# Increase timeout for large queries
lp-api -timeout 30s get ubuntu ws.op==searchTasks
```

## Common Resource Paths

Refer to `references/resource-paths.md` for comprehensive list of resource patterns.

**Quick Reference:**

- **People**: `people/+me`, `~username`
- **Bugs**: `bugs/<id>`
- **Projects**: `<project-name>` (e.g., `ubuntu`, `launchpad`)
- **Distributions**: `ubuntu`, `debian`
- **Teams**: `~team-name`
- **Builds**: `~owner/+livefs/distro/series/name`
- **PPAs**: `~owner/+archive/ubuntu/ppa-name`
- **Branches**: `~owner/project/branch-name`

## API Response Format

All responses are JSON. Common fields across resources:

- `self_link`: Full API URL to this resource
- `web_link`: Human-readable web URL
- `resource_type_link`: Schema/type information
- `http_etag`: For caching/versioning
- `*_collection_link`: Links to related collections

**Tip**: Use `jq` to parse and extract data:

```bash
# Pretty print
lp-api get bugs/1 | jq .

# Extract specific field
lp-api get bugs/1 | jq -r '.title'

# Get array of values
lp-api get bugs/1 | lp-api .bug_tasks_collection_link | jq -r '.entries[].title'
```

## Integration with Other Tools

### With jq (JSON processing)
```bash
# Extract and filter data
lp-api get ubuntu ws.op==searchTasks | \
  jq '.entries[] | select(.importance == "High") | .web_link'
```

### With xargs (batch operations)
```bash
# Download multiple files
lp-api get <build> ws.op==getFileUrls | \
  jq -r '.[]' | \
  xargs -I {} lp-api download {}
```

### With bash loops
```bash
# Process multiple resources
for TAG in focal jammy noble; do
  echo "Bugs for $TAG:"
  lp-api get ubuntu ws.op==searchTasks tags==$TAG ws.show==total_size
done
```

## Error Handling

Common errors and solutions:

1. **"Expired token"**: Remove `~/.config/lp-api.toml` and re-authenticate
2. **401 Unauthorized**: Check OAuth credentials or permissions
3. **404 Not Found**: Verify resource path is correct
4. **Timeout**: Increase with `-timeout` flag
5. **Invalid JSON**: Check `:=` syntax for PATCH, ensure valid JSON values

## When to Use This Skill

Invoke this skill when the user mentions or needs to:

- Query Launchpad bugs, people, or projects
- Update bug status, tags, or properties
- Monitor Ubuntu/Debian package builds
- Download build artifacts from Launchpad
- Search for resources on launchpad.net
- Automate Launchpad workflows
- Integrate Launchpad data into CI/CD pipelines
- Work with PPAs, branches, or source packages

## Resources

This skill includes reference documentation in `references/` directory:

- **resource-paths.md**: Comprehensive guide to Launchpad API resource paths and patterns
- **api-operations.md**: Detailed reference for web service operations (`ws.op=...`)
- **common-workflows.sh**: Shell script library with reusable workflow functions
