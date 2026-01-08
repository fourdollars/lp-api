# Common Workflows

This document collects common workflows for interacting with Launchpad using `lp-api`. These workflows combine multiple operations to achieve specific goals.

## Bug Management

### 1. Bug Investigation
Gather comprehensive information about a bug.

```bash
# 1. Get bug details
lp-api get bugs/1 | jq . 

# 2. Get bug tasks (which projects/packages are affected)
lp-api get bugs/1 | lp-api .bug_tasks_collection_link | jq . 

# 3. Get bug messages/comments
lp-api get bugs/1 | lp-api .messages_collection_link | jq . 

# 4. Check bug subscriptions
lp-api get bugs/1 | lp-api .subscriptions_collection_link | jq . 
```

### 2. Batch Bug Updates
Update multiple bugs at once using shell loops. **Check the count first** to avoid accidentally processing too many bugs.

```bash
# 1. Check how many bugs will be updated
lp-api get ubuntu ws.op==searchTasks tags==needs-update ws.show==total_size

# 2. Search for bugs to update
BUGS=$(lp-api get ubuntu ws.op==searchTasks tags==needs-update | \
       jq -r '.entries[].bug_link')

# 3. Update each bug
for BUG in $BUGS; do
  lp-api patch "$BUG" tags:='["updated","focal"]'
done
```

### 3. Complete Bug Management
Create a bug, analyze it, update properties, and subscribe.

```bash
# 1. Create a new bug
BUG_ID=$(lp-api post ubuntu ws.op=createBug \
  title="Package fails to install on Noble" \
  description="Detailed description of the installation failure" | \
  jq -r '.id')

echo "Created bug: $BUG_ID"

# 2. Add initial comment with analysis
lp-api post "bugs/$BUG_ID" ws.op=newMessage \
  subject="Initial Analysis" \
  content="Root cause: missing dependency on libfoo"

# 3. Update bug properties
lp-api patch "bugs/$BUG_ID" importance:='"High"'
lp-api patch "bugs/$BUG_ID" tags:='["noble","packaging"]'

# 4. Subscribe to bug for updates
lp-api post "bugs/$BUG_ID" ws.op=subscribe
```

### 4. Bulk Comment Addition
Add status updates or comments to multiple bugs.

```bash
# Add status updates to multiple bugs
for BUG_ID in 123456 123457 123458; do
  lp-api post "bugs/$BUG_ID" ws.op=newMessage \
    subject="Status Update" \
    content="Fix has been uploaded to noble-proposed"
done
```

### 5. Triage Workflow
Find new bugs, assign them to yourself, and update their status.

```bash
# 1. Check count of new bugs
lp-api get project ws.op==searchTasks status==New ws.show==total_size

# 2. Find new bugs
lp-api get project ws.op==searchTasks status==New | jq -r '.entries[].self_link'

# 3. Assign to yourself (requires task link)
lp-api patch <task_link> \
  assignee_link:='https://api.launchpad.net/devel/people/+me' \
  status:='"In Progress"'
```

### 6. Release Management
Find fixed bugs to include in release notes.

```bash
lp-api get project ws.op==searchTasks \
  status=="Fix Committed" \
  milestone==<milestone_link>
```

## Build & Release

### 7. Package Build Monitoring
Monitor builds and download artifacts.

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

### 8. Identify Failed Builds
Find builds that failed to identify issues.

```bash
lp-api get ~ubuntu-cdimage/+livefs/ubuntu/noble/ubuntu | \
  lp-api .builds_collection_link | \
  jq -r '.entries[] | select(.buildstate == "Failed to build") | .web_link'
```

## Git & Code Review

### 9. Merge Proposal Review
Review code, view diffs, and post comments on merge proposals.

```bash
# 1. Get merge proposal details and diff
lp-api get ~owner/project/+git/repo/+merge/123

# 2. View the preview diff
DIFF_ID=$(lp-api get ~owner/project/+git/repo/+merge/123 | jq -r '.preview_diff_link' | grep -o '[0-9]*$')
lp-api get ~owner/project/+git/repo/+merge/123/+preview-diff/$DIFF_ID/diff_text

# 3. Add review comment
lp-api post ~owner/project/+git/repo/+merge/123 \
  ws.op=createComment \
  subject="Code Review" \
  content="Overall good work. Please address the following issues:
- Fix typo in volume-id field
- Add input validation for credentials
- Consider adding concurrency controls"

# 4. View all comments on the merge proposal
lp-api get ~owner/project/+git/repo/+merge/123/all_comments
```
