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
