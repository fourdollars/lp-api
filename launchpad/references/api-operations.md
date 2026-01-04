# Launchpad API Web Service Operations

Guide to web service operations (`ws.op=...`) and query parameters for Launchpad API.

## Overview

Launchpad API supports two types of parameters:

1. **Web Service Operations** (`ws.op=<operation>`): Named operations/methods on resources
2. **Query Parameters**: Filter, sort, and control data retrieval

## Common Web Service Operations

### Bug Operations

#### searchTasks
Search for bug tasks across a project or distribution.

**Usage:**
```bash
lp-api get <project-or-distro> ws.op==searchTasks [filters]
```

**Common Filters:**
```bash
# By tags
tags==focal
tags==jammy tags==security tags_combinator==All  # Must have all tags
tags==bug tags==regression tags_combinator==Any  # Must have any tag

# By status
status==New
status==Triaged
status==In Progress
status==Fix Committed
status==Fix Released
status==Incomplete
status==Opinion
status==Invalid
status==Won't Fix

# By importance  
importance==Critical
importance==High
importance==Medium
importance==Low
importance==Wishlist
importance==Undecided

# By assignee
assignee==~username
has_no_assignee==true

# By milestone
milestone==<milestone-name>

# By date
created_since==2024-01-01
modified_since==2024-01-01

# By search text
search_text=="memory leak"

# By structural elements
omit_duplicates==true
omit_targeted==false

# Result control
ws.show==total_size      # Only return count, not results
ws.start==0              # Pagination offset
ws.size==50              # Results per page
order_by==date_created   # Sort order
```

**Examples:**
```bash
# High priority bugs in Ubuntu with both focal and jammy tags
lp-api get ubuntu ws.op==searchTasks \
  importance==High \
  tags==focal \
  tags==jammy \
  tags_combinator==All

# Count of new bugs created this year
lp-api get ubuntu ws.op==searchTasks \
  status==New \
  created_since==2024-01-01 \
  ws.show==total_size

# Unassigned critical bugs
lp-api get firefox ws.op==searchTasks \
  importance==Critical \
  has_no_assignee==true

# List bugs for linux source package
lp-api get ubuntu/+source/linux ws.op==searchTasks ws.size==10

# Get recent bugs for a source package with filters
lp-api get ubuntu/+source/firefox ws.op==searchTasks \
  status==New \
  importance==High \
  ws.size==50
```

#### newMessage
Add a comment/message to a bug.

**Usage:**
```bash
lp-api post bugs/<bug-id> ws.op=newMessage content="<message-text>"
```

**Examples:**
```bash
# Add comment
lp-api post bugs/123456 ws.op=newMessage content="Confirmed on focal"

# Add comment with subject
lp-api post bugs/123456 \
  ws.op=newMessage \
  content="See attached logs" \
  subject="Additional information"
```

#### subscribe / unsubscribe
Manage bug subscriptions.

**Usage:**
```bash
lp-api post bugs/<bug-id> ws.op=subscribe
lp-api post bugs/<bug-id> ws.op=unsubscribe
```

#### addTask
Add a bug task (affect a project/package).

**Usage:**
```bash
lp-api post bugs/<bug-id> ws.op=addTask target=<project-or-package>
```

### Build Operations

#### getFileUrls
Get download URLs for build artifacts.

**Usage:**
```bash
lp-api get <build-resource> ws.op==getFileUrls
```

**Example:**
```bash
# Get all artifact URLs from a build
lp-api get ~ubuntu-cdimage/+livefs/ubuntu/jammy/ubuntu/+build/12345 \
  ws.op==getFileUrls | jq -r '.[]'

# Download all artifacts
lp-api get <build-resource> ws.op==getFileUrls | \
  jq -r '.[]' | \
  xargs -I {} lp-api download {}
```

#### retry
Retry a failed build.

**Usage:**
```bash
lp-api post <build-resource> ws.op=retry
```

#### cancel
Cancel a pending or running build.

**Usage:**
```bash
lp-api post <build-resource> ws.op=cancel
```

### PPA Operations

#### getPublishedSources
List published source packages in a PPA.

**Usage:**
```bash
lp-api get ~owner/+archive/ubuntu/<ppa> \
  ws.op==getPublishedSources \
  distro_series==<series-url> \
  status==Published \
  ws.size==300
```

**Common Filters:**
```bash
# By distribution series
distro_series==https://api.launchpad.net/devel/ubuntu/noble
distro_series==https://api.launchpad.net/devel/ubuntu/jammy

# By status
status==Published
status==Pending
status==Superseded
status==Deleted

# By source package name
source_name==firefox

# By pocket
pocket==Release
pocket==Updates
pocket==Security
```

**Examples:**
```bash
# List all published packages for noble
lp-api get ~oem-solutions-group/+archive/ubuntu/intel-ipu6 \
  ws.op==getPublishedSources \
  distro_series==https://api.launchpad.net/devel/ubuntu/noble \
  status==Published \
  ws.size==300

# List specific package across all series
lp-api get ~owner/+archive/ubuntu/ppa \
  ws.op==getPublishedSources \
  source_name==firefox \
  status==Published

# Get only package count
lp-api get ~owner/+archive/ubuntu/ppa \
  ws.op==getPublishedSources \
  distro_series==https://api.launchpad.net/devel/ubuntu/noble \
  status==Published \
  ws.show==total_size
```

#### getPublishedBinaries
List published binary packages in a PPA.

**Usage:**
```bash
lp-api get ~owner/+archive/ubuntu/<ppa> \
  ws.op==getPublishedBinaries \
  distro_arch_series==<arch-series-url> \
  status==Published \
  binary_name==<package-name> \
  ws.size==300
```

**Common Filters:**
```bash
# By architecture series
distro_arch_series==https://api.launchpad.net/devel/ubuntu/noble/amd64
distro_arch_series==https://api.launchpad.net/devel/ubuntu/jammy/arm64

# By status
status==Published
status==Pending
status==Superseded

# By binary package name
binary_name==firefox
exact_match==true  # Exact match for binary_name

# By version
version==123.0-1ubuntu1

# By pocket
pocket==Release
pocket==Updates
pocket==Security
pocket==Proposed

# Sorting
order_by_date==true  # Sort by publication date
```

**Examples:**
```bash
# List all published binaries for noble amd64
lp-api get ~owner/+archive/ubuntu/ppa \
  ws.op==getPublishedBinaries \
  distro_arch_series==https://api.launchpad.net/devel/ubuntu/noble/amd64 \
  status==Published \
  ws.size==300

# Search for specific binary package with exact match
lp-api get ~owner/+archive/ubuntu/ppa \
  ws.op==getPublishedBinaries \
  binary_name==firefox \
  exact_match==true \
  status==Published

# Query Ubuntu primary archive for specific kernel version
lp-api get ubuntu/+archive/primary \
  ws.op==getPublishedBinaries \
  distro_arch_series==https://api.launchpad.net/devel/ubuntu/noble/amd64 \
  status==Published \
  binary_name=="linux-image-unsigned-6.8.0-48-generic" \
  exact_match==true \
  order_by_date==true \
  version=="6.8.0-48.48"

# Get latest published binary from PPA sorted by date
lp-api get ~canonical-kernel-team/+archive/ubuntu/proposed2/ \
  ws.op==getPublishedBinaries \
  distro_arch_series==https://api.launchpad.net/devel/ubuntu/noble/amd64 \
  status==Published \
  pocket==Release \
  binary_name=="linux-image-unsigned-6.8.0" \
  order_by_date==true | \
  jq -r '.entries | map(select(.source_package_name=="linux-oem-6.8")) | .[0]'
```

#### copyPackage
Copy a package from one archive to another.

**Usage:**
```bash
lp-api post ~owner/+archive/ubuntu/<ppa> \
  ws.op=copyPackage \
  source_name=<package-name> \
  version=<version> \
  from_archive=<source-archive-url> \
  to_pocket=Release \
  to_series=<series-name>
```

#### syncSource
Sync a source package from a primary archive.

**Usage:**
```bash
lp-api post ~owner/+archive/ubuntu/<ppa> \
  ws.op=syncSource \
  source_name=<package-name> \
  to_pocket=Release \
  to_series=<series-name>
```

#### deletePackage
Delete a package from PPA.

**Usage:**
```bash
lp-api post ~owner/+archive/ubuntu/<ppa> \
  ws.op=deletePackage \
  source_name=<package-name> \
  distro_series=<series-url> \
  pocket=Release
```

### Git Recipe Operations

#### createRecipe
Create a git-build-recipe for automated package builds.

**Usage:**
```bash
lp-api post ~owner \
  ws.op=createRecipe \
  build_daily=true \
  daily_build_archive=<archive-url> \
  description="<description>" \
  distroseries=<series-url> \
  name="<recipe-name>" \
  recipe_text="<recipe-content>"
```

**Example:**
```bash
# Create a recipe for daily builds
cat > /tmp/recipe.txt <<'EOF'
# git-build-recipe format 0.4 deb-version {debversion}~{revtime}git{git-commit}
lp:~oem-solutions-engineers/pc-enablement/+git/oem-jammy-projects-meta jammy
EOF

lp-api post ~oem-solutions-engineers \
  ws.op=createRecipe \
  build_daily=true \
  daily_build_archive=https://api.launchpad.net/devel/~oem-solutions-engineers/+archive/ubuntu/oem-projects-meta \
  description="OEM Jammy Projects Meta Daily Build" \
  distroseries=https://api.launchpad.net/devel/ubuntu/jammy \
  name="oem-jammy-projects-meta-daily" \
  recipe_text="$(jq -sR < /tmp/recipe.txt)"
```

#### performDailyBuild
Trigger a daily build for a recipe.

**Usage:**
```bash
lp-api post <recipe-resource> ws.op=performDailyBuild
```

**Example:**
```bash
# Get recipe self_link and trigger build
RECIPE_LINK=$(lp-api get ~owner/project/+git/repo/recipes | \
  jq -r '.entries[] | select(.name=="my-recipe") | .self_link')

lp-api post "$RECIPE_LINK" ws.op=performDailyBuild
```

#### List Recipes
Get all recipes for a git repository.

**Usage:**
```bash
lp-api get ~owner/project/+git/repo/recipes
```

**Example:**
```bash
# List all recipes and check build status
lp-api get ~oem-solutions-engineers/pc-enablement/+git/oem-jammy-projects-meta/recipes | \
  jq -r '.entries[] | "\(.name): build_daily=\(.build_daily)"'
```

### Person/Team Operations

#### getByEmail
Find person by email address.

**Usage:**
```bash
lp-api get people ws.op==getByEmail email==user@example.com
```

#### findTeam
Search for teams.

**Usage:**
```bash
lp-api get people ws.op==findTeam text==ubuntu
```

### Project Operations

#### newTask
Create a new bug task on a project.

**Usage:**
```bash
lp-api post <project> ws.op=newTask \
  title="Bug title" \
  description="Detailed description"
```

#### getTimeline
Get project timeline/activity.

**Usage:**
```bash
lp-api get <project> ws.op==getTimeline
```

### Distribution Operations

#### List Series
Get all series (releases) for a distribution.

**Usage:**
```bash
lp-api get <distro> | lp-api .series_collection_link
```

**Examples:**
```bash
# List all Ubuntu series with status
lp-api get ubuntu | lp-api .series_collection_link | \
  jq -r '.entries[] | "\(.name) (\(.version)) - \(.status)"'

# Filter by status
lp-api get ubuntu | lp-api .series_collection_link | \
  jq -r '.entries[] | select(.status=="Supported") | .name'

# Get current stable release
lp-api get ubuntu | lp-api .series_collection_link | \
  jq -r '.entries[] | select(.status=="Current Stable Release") | "\(.name) (\(.version))"'

# Get active development release
lp-api get ubuntu | lp-api .series_collection_link | \
  jq -r '.entries[] | select(.status=="Active Development") | "\(.name) (\(.version))"'
```

#### getPackageUploads
Check for package uploads in a specific series. Useful for tracking release progress.

**Usage:**
```bash
lp-api get <distro>/<series> \
  ws.op==getPackageUploads \
  name==<package-name> \
  ws.show==total_size
```

**Examples:**
```bash
# Check if a package has been uploaded to Jammy
lp-api get ubuntu/jammy \
  ws.op==getPackageUploads \
  name==firefox \
  ws.show==total_size
```

### Package Set Operations

#### getSourcesIncluded
List source packages included in a package set.

**Usage:**
```bash
lp-api get package-sets/<distro>/<series>/<package-set-name> \
  ws.op==getSourcesIncluded
```

**Examples:**
```bash
# Get sources in OEM metapackages set
lp-api get package-sets/ubuntu/jammy/canonical-oem-metapackages \
  ws.op==getSourcesIncluded | \
  jq -r '.entries[]'
```

## Query Parameters (ws.*)

### Control Parameters

```bash
ws.show==total_size      # Return only the count, not entries
ws.start==<number>       # Pagination offset (default: 0)
ws.size==<number>        # Page size (default varies, max: 300)
```

### Examples:
```bash
# Get total bug count
lp-api get ubuntu ws.op==searchTasks ws.show==total_size

# Paginate through results
lp-api get ubuntu ws.op==searchTasks ws.start==0 ws.size==100
lp-api get ubuntu ws.op==searchTasks ws.start==100 ws.size==100

# Large page size for comprehensive queries
lp-api get ubuntu/+source/firefox ws.op==searchTasks ws.size==300
```

## Collection Filters

### Date Filters

```bash
created_since==YYYY-MM-DD
created_before==YYYY-MM-DD
modified_since==YYYY-MM-DD
modified_before==YYYY-MM-DD
date_created==YYYY-MM-DD      # Exact date
```

### Status Filters

**Valid Bug Statuses:**
- `New`: Just reported, not triaged
- `Incomplete`: Needs more information
- `Opinion`: Not a bug
- `Invalid`: Not relevant
- `Won't Fix`: Acknowledged but won't be fixed
- `Confirmed`: Confirmed as a real bug
- `Triaged`: Confirmed and prioritized
- `In Progress`: Being worked on
- `Fix Committed`: Fixed in development
- `Fix Released`: Fixed and released

### Importance Filters

**Valid Importance Levels:**
- `Critical`: System crash, data loss
- `High`: Major feature broken
- `Medium`: Non-critical feature broken
- `Low`: Minor issue
- `Wishlist`: Enhancement request
- `Undecided`: Not yet prioritized

### Tag Combinators

```bash
tags_combinator==All    # Bug must have ALL specified tags
tags_combinator==Any    # Bug must have ANY of the specified tags
```

**Examples:**
```bash
# Bugs with BOTH focal and jammy tags
lp-api get ubuntu ws.op==searchTasks \
  tags==focal tags==jammy tags_combinator==All

# Bugs with EITHER security or privacy tag
lp-api get ubuntu ws.op==searchTasks \
  tags==security tags==privacy tags_combinator==Any
```

## Sorting Results

```bash
order_by==date_created       # Sort by creation date
order_by==date_last_updated  # Sort by last modification
order_by==importance         # Sort by importance
order_by==status             # Sort by status
order_by==-date_created      # Reverse order (newest first)
```

## Common Workflow Patterns

### 1. Filtered Bug Search with Pagination

```bash
#!/bin/bash
# Find all high-priority bugs for a series, paginated

DISTRO="ubuntu"
TAGS="jammy"
IMPORTANCE="High"
PAGE_SIZE=100

# Get total count
TOTAL=$(lp-api get "$DISTRO" \
  ws.op==searchTasks \
  tags=="$TAGS" \
  importance=="$IMPORTANCE" \
  ws.show==total_size)

echo "Total bugs: $TOTAL"

# Iterate through pages
START=0
while [ $START -lt $TOTAL ]; do
  echo "Fetching bugs $START to $((START + PAGE_SIZE))..."
  
  lp-api get "$DISTRO" \
    ws.op==searchTasks \
    tags=="$TAGS" \
    importance=="$IMPORTANCE" \
    ws.start==$START \
    ws.size==$PAGE_SIZE \
    order_by==date_created | \
    jq -r '.entries[] | .web_link'
  
  START=$((START + PAGE_SIZE))
done
```

### 2. Bulk Build Processing

```bash
#!/bin/bash
# Get all failed builds and retry them

LIVEFS="~ubuntu-cdimage/+livefs/ubuntu/jammy/ubuntu"

# Get builds collection
BUILDS=$(lp-api get "$LIVEFS" | lp-api .builds_collection_link)

# Find failed builds
echo "$BUILDS" | \
  jq -r '.entries[] | select(.buildstate == "Failed") | .self_link' | \
  while read BUILD; do
    echo "Retrying $BUILD"
    lp-api post "$BUILD" ws.op=retry
  done
```

### 3. Tag Management

```bash
#!/bin/bash
# Add tag to all bugs matching criteria

PROJECT="firefox"
SEARCH_TEXT="crash"
NEW_TAG="needs-review"

# Find bugs
BUGS=$(lp-api get "$PROJECT" \
  ws.op==searchTasks \
  search_text=="$SEARCH_TEXT" | \
  jq -r '.entries[] | .bug_link')

# Add tag to each
for BUG in $BUGS; do
  # Get current tags
  CURRENT_TAGS=$(lp-api get "$BUG" | jq -r '.tags[]')
  
  # Add new tag if not present
  if ! echo "$CURRENT_TAGS" | grep -q "$NEW_TAG"; then
    ALL_TAGS=$(echo "$CURRENT_TAGS" "$NEW_TAG" | jq -R -s -c 'split(" ") | map(select(length > 0))')
    lp-api patch "$BUG" tags:="$ALL_TAGS"
    echo "Tagged $BUG"
  fi
done
```

## Parameter Encoding

### Special Characters

When using parameters with special characters, proper encoding is important:

```bash
# Spaces in search text - use quotes
search_text=="memory leak"

# Dates
created_since==2024-01-01

# URLs in parameters
from_archive==https://api.launchpad.net/devel/ubuntu/+archive/primary
```

### Boolean Parameters

```bash
# Boolean true
has_no_assignee==true
omit_duplicates==true

# Boolean false  
has_no_assignee==false
omit_duplicates==false
```

## Discovering Operations

To find available operations for a resource:

1. **Query the resource** and examine `resource_type_link`:
   ```bash
   lp-api get bugs/1 | jq -r '.resource_type_link'
   ```

2. **Check API documentation**:
   - Visit https://api.launchpad.net/devel.html
   - Navigate to resource type
   - Look for "Named operations" section

3. **Common pattern**: Operations are usually verbs (get, search, create, update, delete, sync, copy, retry, cancel, etc.)

## Error Handling

Common operation errors:

```bash
# Operation not found
# → Check spelling and resource type

# Missing required parameter
# → Check API docs for required params

# Permission denied
# → Verify authentication and resource permissions

# Invalid parameter value
# → Check valid values in documentation
```

## Tips

1. **Combine filters** for precise queries:
   ```bash
   lp-api get ubuntu ws.op==searchTasks \
     status==New \
     importance==High \
     tags==jammy \
     created_since==2024-01-01
   ```

2. **Use `ws.show==total_size`** before fetching full results:
   ```bash
   # Check count first
   COUNT=$(lp-api get ubuntu ws.op==searchTasks [...] ws.show==total_size)
   # Then fetch if reasonable
   [ $COUNT -lt 1000 ] && lp-api get ubuntu ws.op==searchTasks [...]
   ```

3. **Leverage jq** for filtering after retrieval:
   ```bash
   lp-api get ubuntu ws.op==searchTasks | \
     jq '.entries[] | select(.importance == "Critical")'
   ```

4. **Save intermediate results** for complex workflows:
   ```bash
   lp-api get ubuntu ws.op==searchTasks > bugs.json
   jq -r '.entries[] | .bug_link' bugs.json > bug-links.txt
   # Process bug-links.txt
   ```
