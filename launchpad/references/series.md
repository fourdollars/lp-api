# Launchpad Series Reference

## What are Series?

In Launchpad, a **series** represents a specific version or release of a distribution or project. For Ubuntu, series correspond to release versions like:

- **focal** - Ubuntu 20.04 LTS
- **jammy** - Ubuntu 22.04 LTS
- **noble** - Ubuntu 24.04 LTS

Series are organized hierarchically:
- **Distributions** (like Ubuntu) contain multiple series
- **Projects** can also have their own series for different versions

## Listing Series

### For a Distribution

```bash
# Get all Ubuntu series
lp-api get ubuntu | lp-api .series_collection_link

# Get series names only
lp-api get ubuntu | lp-api .series_collection_link | jq -r '.entries[].name'

# List series with detailed info (name, display name, status)
lp-api get ubuntu | lp-api .series_collection_link | \
  jq -r '.entries[] | "\(.name): \(.display_name) - \(.status)"'

# Filter active series only
lp-api get ubuntu | lp-api .series_collection_link | \
  jq '.entries[] | select(.status == "Active") | .name'
```

### For a Project

```bash
# Get series for a specific project
lp-api get <project-name> | lp-api .series_collection_link

# Example: List series for the 'launchpad' project
lp-api get launchpad | lp-api .series_collection_link | jq -r '.entries[].name'
```

### Using the Helper Script

The `list_series.sh` script provides a convenient way to list series:

```bash
# List Ubuntu series (default)
./scripts/list_series.sh

# List series for a specific project
./scripts/list_series.sh launchpad

# List series for Debian
./scripts/list_series.sh debian
```

## Using Series in Operations

Series are often used as path components in API calls:

### Package Operations

```bash
# Get packages in a specific series
lp-api get ubuntu/focal

# Get source packages for focal
lp-api get ubuntu/+archive/primary ws.op==getPublishedSources distro_series==https://api.launchpad.net/devel/ubuntu/focal

# Get published packages in focal
lp-api get ubuntu/+archive/primary ws.op==getPublishedBinaries distro_arch_series==https://api.launchpad.net/devel/ubuntu/focal/amd64

# Get package details for a specific package in focal
lp-api get ubuntu/focal/+source/package-name

# Search for packages by name in a series
lp-api get ubuntu/+archive/primary ws.op==getPublishedSources distro_series==https://api.launchpad.net/devel/ubuntu/focal source_name==openssl

# Search bugs in a specific series
lp-api get ubuntu ws.op==searchTasks series==focal

# Search bugs affecting multiple series
lp-api get ubuntu ws.op==searchTasks series==focal series==jammy
```

### Check Package Uploads
Check if a specific package has been uploaded to a series.

**Operation:** `getPackageUploads`

```bash
lp-api get ubuntu/jammy \
  ws.op==getPackageUploads \
  name=="firefox" \
  ws.show==total_size
```

### Build Operations

```bash
# Get builds for a series
lp-api get ~ubuntu-cdimage/+livefs/ubuntu/focal/ubuntu | lp-api .builds_collection_link

# Get live filesystem builds for a series
lp-api get ~ubuntu-cdimage/+livefs/ubuntu/focal/ubuntu

# Get build status for focal
lp-api get ~ubuntu-cdimage/+livefs/ubuntu/focal/ubuntu | lp-api .builds_collection_link | jq -r '.entries[0].buildstate'

# Get recent failed builds in focal
lp-api get ~ubuntu-cdimage/+livefs/ubuntu/focal/ubuntu | lp-api .builds_collection_link | \
  jq '.entries[] | select(.buildstate == "Failed") | .self_link'
```

### PPA Operations

```bash
# Get packages in a PPA for a specific series
lp-api get ~owner/+archive/ubuntu/ppa-name ws.op==getPublishedSources distro_series==https://api.launchpad.net/devel/ubuntu/focal

# PPA builds are typically accessed via livefs if the PPA uses automated builds
```

## Common Series Operations

### Get Series Details

```bash
# Get specific series information
lp-api get ubuntu/focal

# Check if series is supported
lp-api get ubuntu/focal | jq -r '.supported'
```

### Series Status

Series can have different statuses:
- **Active**: Currently supported
- **Supported**: LTS releases
- **Obsolete**: No longer maintained

```bash
# Check series status
lp-api get ubuntu/focal | jq -r '.status'
```

## Automation Examples

### List All Active Ubuntu Series

```bash
lp-api get ubuntu | lp-api .series_collection_link | \
  jq '.entries[] | select(.status == "Active") | .name'
```

### Find Latest Series

```bash
lp-api get ubuntu | lp-api .series_collection_link | \
  jq -r '.entries | sort_by(.date_created) | reverse | .[0].name'
```

## Series in Bug Tracking

Series are important for bug management:

```bash
# Bugs affecting a specific series
lp-api get ubuntu ws.op==searchTasks series==focal

# Bugs affecting multiple series
lp-api get ubuntu ws.op==searchTasks series==focal series==jammy

# High-priority bugs in focal
lp-api get ubuntu ws.op==searchTasks series==focal importance==High

# Create bug task for specific series
lp-api post ubuntu ws.op=createBug title="Bug title" description="Details"

# Update bug to affect additional series
lp-api post bugs/<id> ws.op=addTask target=ubuntu/noble

# Get bug tasks for a specific series
lp-api get bugs/<id> | lp-api .bug_tasks_collection_link | \
  jq '.entries[] | select(.target_link | contains("focal"))'
```

## Workflow Examples

### Monitoring Package Builds Across Series

```bash
# Check build status for a package across all active series
for SERIES in focal jammy noble; do
  echo "Builds for $SERIES:"
  lp-api get ubuntu/$SERIES/+source/package-name | \
    lp-api .builds_collection_link | \
    jq -r '.entries[0].buildstate'
done
```

### Finding Affected Packages in a Series

```bash
# Find all packages in focal that have failed builds
lp-api get ~ubuntu-cdimage/+livefs/ubuntu/focal/ubuntu | lp-api .builds_collection_link | \
  jq -r '.entries[] | select(.buildstate == "Failed") | .source_package_name' | \
  sort | uniq
```

### Series-Specific Bug Triaging

```bash
# Get unassigned bugs in focal
lp-api get ubuntu ws.op==searchTasks series==focal has_no_assignee==true | jq -r '.entries[].id'

# Assign bugs to team for focal maintenance
for BUG in $(lp-api get ubuntu ws.op==searchTasks series==focal status==New | jq -r '.entries[].id'); do
  lp-api patch "bugs/$BUG" assignee_link:='https://api.launchpad.net/devel/~ubuntu-maintainers'
done
```

### Comparing Series Data

```bash
# Compare bug counts across series
echo "Bug counts by series:"
for SERIES in focal jammy noble; do
  COUNT=$(lp-api get ubuntu ws.op==searchTasks series==$SERIES ws.show==total_size | jq -r '.total_size')
  echo "$SERIES: $COUNT bugs"
done
```

## Series vs. Distroseries

- **Series**: General term for versioned releases
- **Distroseries**: Ubuntu-specific series (what you typically work with)

In most contexts, "series" refers to distroseries for Ubuntu.