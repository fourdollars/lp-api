# Launchpad Bug Tracking Reference

Bugs are one of the core resources in Launchpad. This guide provides detailed patterns for working with bugs, bug tasks, and related artifacts.

## Resource Paths

### Core Resources
- **Bug**: `bugs/<id>` (e.g., `bugs/1`)
- **Bug Task**: A bug's context within a specific project or package. Access via collections or directly if you have the link.
- **Bug Attachments**: `bugs/<id>/+attachments`
- **Bug Comments**: `bugs/<id>/+messages`

## Understanding Bug Tasks

In Launchpad, a **Bug** represents the general issue (e.g., "Application crashes on startup"). A **Bug Task** represents the tracking of that issue in a specific context.

**Valid Targets for Bug Tasks:**
- **Distribution**: `ubuntu`, `debian`
- **Distro Series**: `ubuntu/focal`, `ubuntu/jammy` (specific release of a distro)
- **Distribution Source Package**: `ubuntu/+source/openssl` (package across all series)
- **Source Package in Series**: `ubuntu/jammy/+source/openssl` (package in a specific release)
- **Project**: `firefox`, `cloud-init`
- **Project Series**: `launchpad/trunk`, `cloud-init/main` (development line of a project)

**Key Properties of a Bug Task:**
- **Status**: The state of the fix (New, Confirmed, Triaged, In Progress, Fix Committed, Fix Released).
- **Importance**: The priority (Critical, High, Medium, Low, Wishlist).
- **Assignee**: The person responsible for fixing it in this context.
- **Milestone**: The target release for the fix.
- **Target**: The specific entity (above) this task belongs to.

**API Structure:**
A bug resource (`bugs/1`) contains a collection of tasks (`bug_tasks_collection_link`). To change status or assignment, you must operate on the specific **Bug Task** resource (e.g., `https://api.launchpad.net/devel/ubuntu/+bug/1`), not the global bug.

## Searching Bugs (`searchTasks`)

The primary way to find bugs is using the `searchTasks` operation. **Always check the total size first** before fetching results to ensure the query is efficient and the result set is manageable.

**1. Check the count first:**
```bash
lp-api get <target> ws.op==searchTasks [filters...] ws.show==total_size
```

**2. Fetch results (if count is reasonable):**
```bash
lp-api get <target> ws.op==searchTasks [filters...] [ws.size==N]
```

### Valid Targets for Bug Tasks:
- **Distribution**: `ubuntu`, `debian`
- **Distro Series**: `ubuntu/focal`, `ubuntu/jammy`
- **Distribution Source Package**: `ubuntu/+source/openssl`
- **Source Package in Series**: `ubuntu/jammy/+source/openssl`
- **Project**: `firefox`, `cloud-init`
- **Project Series**: `launchpad/trunk`, `cloud-init/main`

### Common Contexts
- **Distribution**: `lp-api get ubuntu ws.op==searchTasks ws.show==total_size`
- **Distro Series**: `lp-api get ubuntu/jammy ws.op==searchTasks ws.show==total_size`
- **Source Package**: `lp-api get ubuntu/+source/linux ws.op==searchTasks ws.show==total_size`
- **Project**: `lp-api get cloud-init ws.op==searchTasks ws.show==total_size`

### Searching Across ALL Projects (Person-level Search)

You can search for bugs **across all projects and distributions** by using `searchTasks` on a person resource. This is useful for finding all bugs you're involved with regardless of which project they belong to.

**Person resource**: `people/+me` or `~username`

```bash
# Get your person link
ME_LINK=$(lp-api get people/+me | jq -r '.self_link')

# Count ALL bugs assigned to you across all projects
lp-api get people/+me ws.op==searchTasks assignee==$ME_LINK ws.show==total_size

# Get all "In Progress" bugs assigned to you
lp-api get people/+me ws.op==searchTasks assignee==$ME_LINK status=="In Progress"

# Bugs you reported (across all projects)
lp-api get people/+me ws.op==searchTasks bug_reporter==$ME_LINK

# Bugs you're subscribed to
lp-api get people/+me ws.op==searchTasks bug_subscriber==$ME_LINK

# Bugs you have activity on (comments, status changes, etc.)
lp-api get people/+me ws.op==searchTasks bug_commenter==$ME_LINK

# Bugs you're marked as affected by
lp-api get people/+me ws.op==searchTasks affected_user==$ME_LINK

# Formatted output - simple list of titles (already includes bug numbers)
lp-api get people/+me ws.op==searchTasks assignee==$ME_LINK status=="In Progress" | \
  jq -r '.entries[].title'

# Or extract just bug number and description
lp-api get people/+me ws.op==searchTasks assignee==$ME_LINK status=="In Progress" | \
  jq -r '.entries[] | (.bug_link | split("/")[-1]) + ": " + (.title | split(": ")[1:] | join(": "))'
```

**Note:** 
- The `assignee`, `bug_reporter`, `bug_subscriber`, `bug_commenter`, and `affected_user` parameters require the full API link (e.g., `https://api.launchpad.net/devel/~username`), not just the username. Use `jq -r '.self_link'` to extract it from the person resource.
- `bug_commenter` includes any bug activity (comments, status changes, field updates), not just message comments.

## Targeting Bug Tasks

### Add a New Target (Task) to a Bug
**Operation:** `addTask`
**Resource:** `bugs/<id>`

Use this to make an existing bug affect another project, distribution, or series.

**Important:** The `target` parameter requires a **full API URI**, not a short path.

```bash
# Make bug affect a distribution source package
lp-api post bugs/123456 ws.op=addTask \
  target=https://api.launchpad.net/devel/ubuntu/+source/linux

# Make bug affect a specific distro series package
lp-api post bugs/123456 ws.op=addTask \
  target=https://api.launchpad.net/devel/ubuntu/noble/+source/linux

# Make bug affect another project
lp-api post bugs/123456 ws.op=addTask \
  target=https://api.launchpad.net/devel/launchpad

# Get target URI from resource (example workflow)
TARGET=$(lp-api get ubuntu/jammy/+source/openssl | jq -r '.self_link')
lp-api post bugs/123456 ws.op=addTask target="$TARGET"
```

### Remove a Bug Task
**Operation:** `delete` (HTTP DELETE)
**Resource:** Bug task self_link

Remove a bug task to stop tracking a bug in a specific context.

```bash
# 1. List all tasks for a bug
lp-api get bugs/123456 | jq -r '.bug_tasks_collection_link' | xargs lp-api get | \
  jq -r '.entries[] | "\(.bug_target_display_name): \(.self_link)"'

# 2. Delete a specific task
lp-api delete https://api.launchpad.net/devel/ubuntu/+source/linux/+bug/123456

# 3. Delete multiple tasks (e.g., all tasks for a specific package)
lp-api get bugs/123456 | jq -r '.bug_tasks_collection_link' | xargs lp-api get | \
  jq -r '.entries[] | select(.bug_target_name | contains("old-package")) | .self_link' | \
  xargs -I {} lp-api delete {}
```

**Important Notes:**
- This is a permanent deletion - the task cannot be recovered
- Use with caution - deleting tasks removes tracking history
- Not documented in the official API, but works via HTTP DELETE
- The bug itself is not deleted, only the specific task context

### Key Filters

| Filter | Description | Examples |
|--------|-------------|----------|
| `status` | Bug status | `New`, `Confirmed`, `Triaged`, `In Progress`, `Fix Committed`, `Fix Released` |
| `importance` | Bug priority | `Critical`, `High`, `Medium`, `Low` |
| `tags` | Tags on the bug | `tags==regression`, `tags==-needs-info` (exclude) |
| `tags_combinator` | How to combine tags | `Any` (OR), `All` (AND) |
| `assignee` | Who is working on it | `~username` |
| `has_patch` | Has a patch attached | `true` |
| `modified_since` | Changed after date | `2024-01-01` |
| `created_since` | Created after date | `2024-01-01` |

### Count and Status Filters

When querying bugs with `ws.op==searchTasks` you can request only the total count by using `ws.show==total_size`. This returns a **plain text integer number** (not a JSON object).

**Status Filtering Rules:**
- Use `status==<Status>` (exact values must match `lp-api get /`).
- Include one `status==` per status you want to include.
- **Archive-only statuses** (`Published`, `Pending`, `Superseded`, `Deleted`) apply to archive/package resources and should be excluded when querying active project bugs.

**Example — count all non-archive Somerville bugs assigned to the current user:**
```bash
ME_LINK=$(lp-api get people/+me | jq -r '.self_link') && \
lp-api get somerville ws.op==searchTasks assignee==$ME_LINK \
  status==New status==Incomplete status==Opinion status==Invalid \
  status=="Won't Fix" status==Expired status==Confirmed status==Triaged \
  status=="In Progress" status=="Fix Committed" status=="Fix Released" \
  ws.show==total_size
```

### Examples

**Find high-priority bugs in Ubuntu:**
```bash
lp-api get ubuntu ws.op==searchTasks \
  importance==High \
  status==Confirmed \
  status==Triaged \
  ws.size==20
```

**Find bugs tagged 'security' in a package:**
```bash
lp-api get ubuntu/+source/nginx ws.op==searchTasks \
  tags==security
```

## Creating Bugs

Bugs are usually created on a specific target (Distribution or Project).

**Operation:** `createBug`
**Resource:** `<target>`

```bash
# Create a bug on Ubuntu
lp-api post ubuntu ws.op=createBug \
  title="App crashes on startup" \
  description="Steps to reproduce: 1. Run app..." \
  tags="crash regression"
```

## Modifying Bugs

Most bug modifications happen via `PATCH` requests to the bug resource or specific bug task.

### Updating Bug Details (Global)
These changes affect the bug across all contexts.

```bash
# Update tags (overwrite list)
lp-api patch bugs/123456 tags:='["regression", "ui"]'

# Update title
lp-api patch bugs/123456 title:='"New Title"'

# Update description (multiline text)
# Method 1: From file (recommended for long descriptions)
lp-api patch bugs/123456 "description:=$(jq -sR < description.txt)"

# Method 2: Inline short description
lp-api patch bugs/123456 "description:=$(echo 'Short description' | jq -sR)"
```

**Note on Description Updates:**
- Use `jq -sR` (slurp raw input) to properly JSON-encode multiline text for the `:=` operator
- The `:=` operator expects JSON input, while `=` expects plain text
- For multiline descriptions, always use file input with `jq -sR < file.txt`

### Updating Bug Status (Per Task)
Status, importance, and assignments are properties of a **Bug Task** (the bug's context within a specific project or package).

1. **Find the bug task link:**
   ```bash
   lp-api get bugs/123456 | lp-api .bug_tasks_collection_link
   ```
2. **Patch the task:**
   ```bash
   lp-api patch <bug_task_self_link> \
     status:='"In Progress"' \
     importance:='"High"'
   ```

### Assigning Bugs
Assigning a bug is done by updating the `assignee_link` on the specific **Bug Task**.

```bash
# Change assignee (operates on bug task, not bug directly)
lp-api patch <bug-task-link> \
  assignee_link:='https://api.launchpad.net/devel/~username'
```

## Comments & Communication

### Adding a Comment
**Operation:** `newMessage`
**Resource:** `bugs/<id>`

```bash
lp-api post bugs/123456 ws.op=newMessage \
  content="I have reproduced this issue on version 2.0." \
  subject="Reproduction Steps"
```

### Removing Comment Content
**Operation:** `deleteContent` (on message resource)
**Resource:** Message self_link from bug's messages collection

You cannot delete a comment entirely, but you can delete its content, leaving a placeholder.

```bash
# 1. Get the bug's messages
lp-api get bugs/123456/messages | jq -r '.entries[].self_link'

# 2. Delete content of a specific message
MESSAGE_LINK="https://api.launchpad.net/devel/bugs/123456/messages/5"
lp-api post "$MESSAGE_LINK" ws.op=deleteContent

# Example: Delete comment #2 content
lp-api get bugs/123456/messages | \
  jq -r '.entries[1].self_link' | \
  xargs -I {} lp-api post {} ws.op=deleteContent
```

**Important Notes:**
- Comments are indexed starting from 0, but displayed as #1, #2, etc. in the UI
- Entry 0 is usually the bug description, entry 1 is comment #2, etc.
- Use `.entries[1]` for comment #2, `.entries[2]` for comment #3, etc.
- After deletion, the comment shows as "(removed)" in the UI but the message object remains

## Bug Subscriptions

### Subscribe to a Bug
**Operation:** `subscribe`
```bash
lp-api post bugs/123456 ws.op=subscribe
```

### Unsubscribe from a Bug
**Operation:** `unsubscribe`
```bash
lp-api post bugs/123456 ws.op=unsubscribe
```

## Bug Duplicates

### Mark as Duplicate
**Operation:** `markAsDuplicate`
```bash
lp-api post bugs/123456 ws.op=markAsDuplicate duplicate_of=/bugs/123455
```

## Attachments

### Uploading Files
**Operation:** `addAttachment`
**Resource:** `bugs/<id>`

**Parameters:**
- `attachment=@filepath` (Required, use `@` prefix)
- `comment="text"` (Required)
- `description="text"` (Optional)
- `is_patch=true` (Optional, for .patch/.diff)
- `content_type="mime/type"` (Optional)

```bash
# Standard attachment
lp-api post bugs/123456 ws.op=addAttachment \
  attachment=@/path/to/file.log \
  comment="Production error log"

# With optional description
lp-api post bugs/123456 ws.op=addAttachment \
  attachment=@error.log \
  comment="Error log from production" \
  description="Log file showing the database connection timeout"

# Patch/Diff
lp-api post bugs/123456 ws.op=addAttachment \
  attachment=@fix.patch \
  comment="Proposed fix" \
  is_patch=true

# Diff as patch with description
lp-api post bugs/123456 ws.op=addAttachment \
  attachment=@bugfix.diff \
  comment="Proposed fix for regression" \
  is_patch=true \
  description="This patch reverts the problematic commit"

# Image attachment
lp-api post bugs/123456 ws.op=addAttachment \
  attachment=@screenshot.png \
  comment="UI bug screenshot"

# Config file
lp-api post bugs/123456 ws.op=addAttachment \
  attachment=@config.yaml \
  comment="Configuration file that triggers the bug"
```

**File Upload Features:**
- Automatic MIME type detection from file extension.
- Supports text files (.log, .txt), patches (.patch, .diff), images (.png, .jpg), configs (.json, .yaml), archives (.tar.gz).
- Automatic filename detection from file path.
- Clear error messages for missing files or permission issues.
- Patch files are automatically marked when `is_patch=true` is set.

**Important Notes:**
- The `comment` parameter is **required** (not optional).
- The `attachment` parameter must use `@` prefix for file paths.
- Files are read into memory, suitable for typical bug attachments (<10MB).
- Use absolute or relative file paths.
- Binary files are supported (images, archives, etc.).
- For patch files (.patch, .diff), set `is_patch=true` to properly categorize them.

### Downloading Files
Files are typically accessed via their URL.

```bash
lp-api download <file-url>
```

### Removing Attachments
**Operation:** `removeFromBug` (on bug_attachment resource)
**Resource:** Attachment self_link from bug's attachments collection

```bash
# 1. List all attachments on a bug
lp-api get bugs/123456/attachments | \
  jq -r '.entries[] | "\(.id): \(.title) (\(.self_link))"'

# 2. Remove a specific attachment
ATTACHMENT_LINK="https://api.launchpad.net/devel/bugs/123456/+attachment/5940015"
lp-api post "$ATTACHMENT_LINK" ws.op=removeFromBug

# Example: Remove attachment by title pattern
lp-api get bugs/123456/attachments | \
  jq -r '.entries[] | select(.title | contains("old-version")) | .self_link' | \
  xargs -I {} lp-api post {} ws.op=removeFromBug

# Example: Remove most recent attachment
lp-api get bugs/123456/attachments | \
  jq -r '.entries[-1].self_link' | \
  xargs -I {} lp-api post {} ws.op=removeFromBug
```

**Important Notes:**
- Attachments are permanently removed from the bug (not just hidden)
- The operation is `removeFromBug`, not `delete`
- You need the attachment's self_link, which includes the attachment ID
- Use `jq` filters to find the right attachment before removing it

## Common Workflows

### 1. Triage Workflow
Find new bugs, assign them, and update status.

```bash
# 1. Find new bugs
lp-api get project ws.op==searchTasks status==New | jq -r '.entries[].self_link'

# 2. Assign to yourself (requires task link)
lp-api patch <task_link> \
  assignee_link:='https://api.launchpad.net/devel/people/+me' \
  status:='"In Progress"'
```

### 2. Batch Bug Updates
Update multiple bugs at once using shell loops.

```bash
# Search for bugs to update
BUGS=$(lp-api get ubuntu ws.op==searchTasks tags==needs-update | \
       jq -r '.entries[].bug_link')

# Update each bug
for BUG in $BUGS; do
  lp-api patch "$BUG" tags:='["updated","focal"]'
done
```

### 3. Release Management
Find fixed bugs to include in release notes.

```bash
lp-api get project ws.op==searchTasks \
  status=="Fix Committed" \
  milestone==<milestone_link>
```

### 4. Complete Bug Management
Create, analyze, and subscribe to a bug.

```bash
# 1. Create bug
BUG_ID=$(lp-api post ubuntu ws.op=createBug \
  title="Installation failure" \
  description="Details..." | jq -r '.id')

# 2. Add analysis comment
lp-api post "bugs/$BUG_ID" ws.op=newMessage \
  subject="Analysis" \
  content="Root cause identified..."

# 3. Update properties
lp-api patch "bugs/$BUG_ID" importance:='"High"'

# 4. Subscribe
lp-api post "bugs/$BUG_ID" ws.op=subscribe
```

## Activity & History

Tracking your exact activity on Launchpad requires client-side filtering because the API's `searchTasks` filters (like `bug_commenter`) return bugs you are *involved* in, not just bugs you explicitly modified.

### Checking Recent Activity

To find actions you performed (status changes, comments, attachment uploads), you must:
1. Search for bugs you are involved in.
2. Iterate through them and fetch their `activity` and `messages` history.
3. Filter the entries using `jq` to match your user link and date range.

**Example: Check your activity since Jan 1, 2026**

```bash
# 1. Setup variables
ME_LINK=$(lp-api get people/+me | jq -r '.self_link')
SINCE="2026-01-01"

# 2. Get bugs you are involved with (commenter includes all activity types)
# Note: bug_commenter requires the full API URL, not just ~username
# Use ws.size to fetch more results if needed
BUGS=$(lp-api get people/+me ws.op==searchTasks \
  bug_commenter=="$ME_LINK" \
  modified_since==$SINCE \
  ws.size==50 | jq -r '.entries[].bug_link' | sort -u)

# 3. Iterate and filter strictly for YOUR actions
for BUG_URL in $BUGS; do
  BUG_ID=$(basename "$BUG_URL")
  echo "Checking Bug $BUG_ID..."

  # Check activity (status changes, importance, assignments)
  lp-api get "bugs/$BUG_ID/activity" | \
    jq --arg ME "$ME_LINK" --arg DATE "$SINCE" \
    '.entries[] | select(.person_link == $ME and .datechanged >= $DATE)'

  # Check messages (comments)
  lp-api get "bugs/$BUG_ID/messages" | \
    jq --arg ME "$ME_LINK" --arg DATE "$SINCE" \
    '.entries[] | select(.owner_link == $ME and .date_created >= $DATE)'
done
```

**Key Differences:**
- `searchTasks` with `bug_commenter` finds bugs where you did *something* historically.
- The `jq` filter `select(.person_link == $ME)` ensures you only see the specific actions *you* performed recently, ignoring updates by others on the same bugs.

