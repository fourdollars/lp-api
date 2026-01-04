# Launchpad Bug Tracking Reference

Bugs are one of the core resources in Launchpad. This guide provides detailed patterns for working with bugs, bug tasks, and related artifacts.

## Resource Paths

### Core Resources
- **Bug**: `bugs/<id>` (e.g., `bugs/1`)
- **Bug Task**: A bug's context within a specific project or package. Access via collections or directly if you have the link.
- **Bug Attachments**: `bugs/<id>/+attachments`
- **Bug Comments**: `bugs/<id>/+messages`

## Searching Bugs (`searchTasks`)

The primary way to find bugs is using the `searchTasks` operation on a context (Project, Distribution, or Package).

**Base Command:**
```bash
lp-api get <context> ws.op==searchTasks [filters...]
```

### Common Contexts
- **Distribution**: `ubuntu`, `debian`
- **Project**: `firefox`, `cloud-init`
- **Source Package**: `ubuntu/+source/linux`
- **Person**: `~username` (bugs assigned to or reported by)

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
lp-api patch bugs/12345 tags:='["regression", "ui"]'

# Update title or description
lp-api patch bugs/12345 title:='"New Title"'
```

### Updating Bug Status (Per Task)
Status and importance are properties of a "Bug Task" (e.g., the bug's status in Ubuntu vs. Debian).

1. **Find the bug task link:**
   ```bash
   lp-api get bugs/12345 | lp-api .bug_tasks_collection_link
   ```
2. **Patch the task:**
   ```bash
   lp-api patch <bug_task_self_link> \
     status:='"In Progress"' \
     importance:='"High"' \
     assignee_link:='https://api.launchpad.net/devel/~username'
   ```

## Comments & Communication

### Adding a Comment
**Operation:** `newMessage`
**Resource:** `bugs/<id>`

```bash
lp-api post bugs/12345 ws.op=newMessage \
  content="I have reproduced this issue on version 2.0." \
  subject="Reproduction Steps"
```

## Attachments

### Uploading Files
**Operation:** `addAttachment`
**Resource:** `bugs/<id>`

```bash
lp-api post bugs/12345 ws.op=addAttachment \
  attachment=@/path/to/log.txt \
  comment="System logs from crash"
```

**Common Parameters:**
- `attachment`: File path (use `@` prefix)
- `comment`: Description of file
- `is_patch`: `true` if it's a code patch/diff
- `content_type`: MIME type (optional, auto-detected)

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

### 2. Release Management
Find fixed bugs to include in release notes.

```bash
lp-api get project ws.op==searchTasks \
  status=="Fix Committed" \
  milestone==<milestone_link>
```
