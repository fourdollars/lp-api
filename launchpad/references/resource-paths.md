# Launchpad API Resource Paths Reference

Complete guide to Launchpad API resource paths and patterns based on https://api.launchpad.net/devel.html

## General Path Structure

Launchpad resources follow REST conventions:
- Base URL: `https://api.launchpad.net/devel/`
- Resource paths are hierarchical and human-readable
- Collection paths typically end with plural nouns
- Individual resources use singular identifiers

## People & Teams

### Person Resources
```bash
# Current authenticated user
people/+me

# Specific person by username
~username
people/username

# Person by Launchpad ID
people/<person-id>

# Person's details
~username/+participation
~username/+memberships
~username/+packages
```

### Team Resources
```bash
# Team by name
~team-name

# Team members
~team-name/+members

# Team PPAs
~team-name/+archive
```

## Bugs & Bug Tracking

### Bug Resources
```bash
# Specific bug by number
bugs/<bug-id>

# Bug tasks (project/package assignments)
bugs/<bug-id>/+bug-tasks

# Bug messages/comments
bugs/<bug-id>/+messages

# Bug attachments
bugs/<bug-id>/+attachments
bugs/<bug-id>/+attachment/<attachment-id>

# Bug subscribers
bugs/<bug-id>/+subscriptions
```

### Bug Search Operations
```bash
# Search bugs with web service operations (see api-operations.md)
<project> ws.op==searchTasks
ubuntu ws.op==searchTasks tags==focal
ubuntu/+source/firefox ws.op==searchTasks status==New

# List bugs for a source package (use searchTasks, not +bugs path)
ubuntu/+source/linux ws.op==searchTasks ws.size==10
ubuntu/+source/firefox ws.op==searchTasks status==New ws.size==50

# Note: Direct paths like ubuntu/+source/<package>/+bugs return 404
# Always use ws.op==searchTasks instead
```

## Projects & Products

### Project Resources
```bash
# Project by name
<project-name>
launchpad
firefox
ubuntu

# Project series/releases
<project>/+milestone/<milestone-name>
<project>/<series-name>

# Project branches
<project>/+git
<project>/+branch/<branch-name>
```

## Distributions & Packages

### Distribution Resources
```bash
# Distribution
ubuntu
debian

# Distribution series
ubuntu/jammy
ubuntu/focal
debian/bookworm

# Distribution architectures
ubuntu/jammy/amd64
ubuntu/jammy/arm64

# Primary archive (main Ubuntu repository)
ubuntu/+archive/primary
debian/+archive/primary

# List all series for a distribution
ubuntu | .series_collection_link
```

**List Ubuntu Series:**
```bash
# Get all Ubuntu series with status
lp-api get ubuntu | lp-api .series_collection_link | \
  jq -r '.entries[] | "\(.name) (\(.version)) - \(.status)"'

# Get only supported series
lp-api get ubuntu | lp-api .series_collection_link | \
  jq -r '.entries[] | select(.status=="Supported" or .status=="Current Stable Release") | "\(.name) (\(.version))"'

# Get active development series
lp-api get ubuntu | lp-api .series_collection_link | \
  jq -r '.entries[] | select(.status=="Active Development") | "\(.name) (\(.version))"'
```

**Current Ubuntu Series (as of 2026-01):**
- **Active Development**: resolute (26.04)
- **Current Stable**: questing (25.10)
- **Supported LTS**: noble (24.04), jammy (22.04), focal (20.04), bionic (18.04), xenial (16.04), trusty (14.04)
- **Supported**: plucky (25.04)

### Source Package Resources
```bash
# Source package in distribution
ubuntu/+source/<package-name>

# Package in specific series
ubuntu/jammy/+source/<package-name>

# Package publishing history
ubuntu/+source/<package-name>/+publishing-history

# Package builds
ubuntu/+source/<package-name>/+build/<build-id>
```

### Binary Package Resources
```bash
# Binary package
ubuntu/+binary/<package-name>

# Binary in architecture
ubuntu/jammy/amd64/+binary/<package-name>
```

### Package Sets
```bash
# Package sets (groups of packages)
package-sets/<distro>/<series>/<package-set-name>

# Example
package-sets/ubuntu/jammy/canonical-oem-metapackages
```

### Package Uploads
```bash
# Check uploads for a specific package in a series
<distro>/<series> ws.op==getPackageUploads name==<package-name>

# Example
ubuntu/jammy ws.op==getPackageUploads name==linux-firmware
```

## Builds & Build Farm

### LiveFS Builds
```bash
# LiveFS configuration
~owner/+livefs/<distro>/<series>/<livefs-name>

# LiveFS builds collection
~owner/+livefs/<distro>/<series>/<livefs-name> | .builds_collection_link

# Specific build
~owner/+livefs/<distro>/<series>/<livefs-name>/+build/<build-id>

# Example: Ubuntu CD Images
~ubuntu-cdimage/+livefs/ubuntu/jammy/ubuntu
~ubuntu-cdimage/+livefs/ubuntu/jammy/ubuntu-server
```

### Source Package Builds
```bash
# Build record
ubuntu/+build/<build-id>

# Build for source package
ubuntu/+source/<package>/+build/<build-id>

# Build log
ubuntu/+build/<build-id>/+file/<log-file>
```

### Build Farm Builders
```bash
# All builders
+builds

# Specific builder
+builds/<builder-name>
```

## PPAs (Personal Package Archives)

### PPA Resources
```bash
# PPA by owner and name
~owner/+archive/ubuntu/<ppa-name>

# PPA packages
~owner/+archive/ubuntu/<ppa-name>/+packages

# PPA builds
~owner/+archive/ubuntu/<ppa-name>/+builds

# PPA signing key
~owner/+archive/ubuntu/<ppa-name>/+signing-key

# Example
~mozillateam/+archive/ubuntu/ppa
~oem-solutions-group/+archive/ubuntu/intel-ipu6
~oem-solutions-engineers/+archive/ubuntu/pc-enablement-tools
```

### PPA Package Listing
```bash
# List published source packages (use ws.op==getPublishedSources)
~owner/+archive/ubuntu/<ppa-name> ws.op==getPublishedSources \
  distro_series==https://api.launchpad.net/devel/ubuntu/noble \
  status==Published

# List published binary packages
~owner/+archive/ubuntu/<ppa-name> ws.op==getPublishedBinaries \
  distro_arch_series==https://api.launchpad.net/devel/ubuntu/noble/amd64 \
  status==Published

# Examples
lp-api get ~oem-solutions-group/+archive/ubuntu/intel-ipu6 \
  ws.op==getPublishedSources \
  distro_series==https://api.launchpad.net/devel/ubuntu/noble \
  status==Published \
  ws.size==300
```

### PPA Package Publishing
```bash
# Published sources in PPA
~owner/+archive/ubuntu/<ppa-name>/+sourcepub/<pub-id>

# Published binaries in PPA
~owner/+archive/ubuntu/<ppa-name>/+binarypub/<pub-id>
```

## Source Code Management

### Git Repositories
```bash
# Repository
~owner/<project>/+git/<repo-name>

# Repository refs (branches/tags)
~owner/<project>/+git/<repo-name>/+ref/<ref-name>

# Repository recipes (git-build-recipe)
~owner/<project>/+git/<repo-name>/recipes

# Example
~ubuntu-core-dev/ubuntu/+git/ubuntu-seeds
~oem-solutions-engineers/pc-enablement/+git/oem-jammy-projects-meta
~oem-solutions-engineers/pc-enablement/+git/oem-jammy-projects-meta/recipes
```

### Bazaar Branches (Legacy)
```bash
# Branch
~owner/<project>/<branch-name>

# Example
~ubuntu-branches/ubuntu/jammy/firefox
```

## Translations

### Translation Resources
```bash
# Project translations
<project>/+translations

# Distribution translations
ubuntu/jammy/+translations

# POT template
<project>/+pots/<template-name>

# PO file
<project>/+pots/<template-name>/<language>
```

## Specifications & Blueprints

### Specification Resources
```bash
# Project specifications
<project>/+specs

# Specific specification
<project>/+spec/<spec-name>

# Example
ubuntu/+spec/foundations-p-minimal-server
```

## Questions & Answers

### Question Resources
```bash
# Project questions
<project>/+questions

# Specific question
<project>/+question/<question-id>

# Distribution package questions
ubuntu/+source/<package>/+questions
```

## Milestones & Releases

### Milestone Resources
```bash
# Project milestone
<project>/+milestone/<milestone-name>

# Distribution milestone
ubuntu/<series>

# Milestone bugs
<project>/+milestone/<milestone-name>/+bugs
```

## Collections & Pagination

Most collection endpoints return paginated results with these fields:

```json
{
  "total_size": 1234,
  "start": 0,
  "entries": [...],
  "next_collection_link": "...",
  "prev_collection_link": "..."
}
```

**Parameters for pagination:**
```bash
# Control pagination
ws.start==0          # Offset (default: 0)
ws.size==50          # Page size (default: varies, max: 300)
ws.show==total_size  # Just return count, not entries
```

## Resource Link Fields

Most resources include these link fields (ending in `_link`):

- `self_link`: API URL to this resource
- `web_link`: Human-readable web URL  
- `*_collection_link`: Related collection (e.g., `bug_tasks_collection_link`)
- `*_link`: Related single resource (e.g., `owner_link`, `project_link`)
- `build_link`: Link to build resource (from publishing history)
- `changesfile_url`: URL to .changes file (from build resource)

**Following links with lp-api:**
```bash
# Extract link field and query it
lp-api get bugs/1 | lp-api .bug_tasks_collection_link
lp-api get ubuntu/+source/firefox | lp-api .owner_link

# Get build information from published binary
lp-api get ubuntu/+archive/primary \
  ws.op==getPublishedBinaries \
  distro_arch_series==https://api.launchpad.net/devel/ubuntu/noble/amd64 \
  binary_name=="linux-image-unsigned-6.8.0-48-generic" \
  exact_match==true \
  order_by_date==true | \
  jq -r '.entries[0]' | \
  lp-api .build_link

# Get changes file URL from build
lp-api get <build-resource> | jq -r .changesfile_url
```

## Constructing Resource Paths

### Pattern Examples

1. **Owner-based resources**: `~<owner>/+<resource-type>/<details>`
   - `~username/+archive/ubuntu/ppa-name`
   - `~username/project/+git/repo`

2. **Project-based resources**: `<project>/+<resource-type>/<details>`
   - `ubuntu/+source/firefox`
   - `launchpad/+spec/better-api`

3. **Hierarchical resources**: `<parent>/<child>/<grandchild>`
   - `ubuntu/jammy/amd64`
   - `firefox/1.0/+milestone/1.0-final`

### Special Tokens

- `+me`: Current authenticated user (only in `people/+me`)
- `+bugs`, `+specs`, `+questions`: Resource type indicators
- `+source`, `+binary`: Package type indicators
- `+git`, `+branch`: VCS indicators
- `+archive`: PPA indicator
- `+livefs`, `+build`: Build system indicators

## Tips for Discovery

1. **Start broad, then narrow:**
   ```bash
   lp-api get ubuntu                    # Get distribution
   lp-api get ubuntu/jammy              # Get series
   lp-api get ubuntu/jammy/+source/vim  # Get package
   ```

2. **Follow links in responses:**
   ```bash
   # Get resource, examine JSON for *_link fields, follow them
   lp-api get bugs/1 | jq 'keys | .[] | select(endswith("_link"))'
   ```

3. **Use web_link to browse:**
   ```bash
   # Extract web_link and open in browser
   lp-api get ubuntu/+source/firefox | jq -r '.web_link'
   ```

4. **Check the official API docs:**
   - https://api.launchpad.net/devel.html
   - Explore resource types and their available operations

## Common Path Mistakes

❌ **Incorrect:**
- `bugs/bug-1` (should be `bugs/1`)
- `ubuntu/firefox` (should be `ubuntu/+source/firefox`)
- `people/username` (prefer `~username`)
- `/devel/bugs/1` (don't include API version in path with lp-api)

✅ **Correct:**
- `bugs/1`
- `ubuntu/+source/firefox`
- `~username`
- `bugs/1` (lp-api adds base URL automatically)
