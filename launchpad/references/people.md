# Launchpad People & Teams Reference

People and Teams are fundamental concepts in Launchpad. A "Person" resource can represent an individual user or a Team.

## Resource Paths

### Authenticated User
`people/+me`

### Specific Person/Team
`~<username>` or `people/<username>`

Example: `~canonical-is`

## Querying People

### Get Person Details
Retrieve information about a user or team.

```bash
lp-api get ~username
```

Key fields:
- `name`: Unique identifier (username)
- `display_name`: Human-readable name
- `is_team`: Boolean indicating if this is a team
- `members_collection_link`: Link to team members (if it's a team)
- `team_owner_link`: Link to team owner

### Find Person by Email
**Operation:** `getByEmail`
**Resource:** `people`

```bash
lp-api get people ws.op==getByEmail email==user@example.com
```

### Search for People/Teams
**Operation:** `findPerson` or `findTeam`
**Resource:** `people`

```bash
# Find any person or team
lp-api get people ws.op==findPerson text=="Canonical"

# Find only teams
lp-api get people ws.op==findTeam text=="Ubuntu"
```

## Team Management

### List Team Members
**Resource:** `~team/+members`

```bash
lp-api get ~my-team/members | lp-api .members_collection_link | \
  jq -r '.entries[] | .name'
```

### Create a New Team
**Operation:** `newTeam`
**Resource:** `people`

```bash
lp-api post people \
  ws.op=newTeam \
  name="my-new-team" \
  display_name="My New Team" \
  team_description="A description of the team" \
  subscription_policy="Open Team"
```

**Subscription Policies:**
- `Open Team`: Anyone can join
- `Delegated Team`: Join requests must be approved
- `Moderated Team`: Join requests must be approved, mailing list is moderated
- `Restricted Team`: Membership is controlled by admins

## Memberships

### Join a Team
To join a team, you typically create a membership via the team resource (if open) or request membership.

*(Note: Specific operations for joining vary by team policy and API permissions)*

### Check Team Membership
To check if a user is a member of a team, you can iterate through the team's members or check the user's memberships.

```bash
# Check user's memberships
lp-api get ~username | lp-api .memberships_collection_link
```

## User Resources

### User's PPAs
`~username/+archive`

```bash
lp-api get ~username/+archive/ubuntu/ppa
```

### User's Bug Involvement

You can search for bugs at the **person level** to find all bugs a user is involved with **across all projects and distributions**.

**Search bugs assigned to a specific user:**
```bash
# In a specific project/distribution (requires full link)
USER_LINK=$(lp-api get ~username | jq -r '.self_link')
lp-api get ubuntu ws.op==searchTasks assignee==$USER_LINK

# Across ALL projects (person-level search)
USER_LINK=$(lp-api get ~username | jq -r '.self_link')
lp-api get ~username ws.op==searchTasks assignee==$USER_LINK
```

**Search YOUR bugs across all projects:**
```bash
# Get your person link
ME_LINK=$(lp-api get people/+me | jq -r '.self_link')

# Count all bugs assigned to you
lp-api get people/+me ws.op==searchTasks assignee==$ME_LINK ws.show==total_size

# Get "In Progress" bugs assigned to you
lp-api get people/+me ws.op==searchTasks assignee==$ME_LINK status=="In Progress"

# Bugs you reported
lp-api get people/+me ws.op==searchTasks bug_reporter==$ME_LINK

# Bugs you're subscribed to
lp-api get people/+me ws.op==searchTasks bug_subscriber==$ME_LINK

# Bugs you have activity on (comments, status changes, field updates, etc.)
lp-api get people/+me ws.op==searchTasks bug_commenter==$ME_LINK

# Bugs where you're marked as affected
lp-api get people/+me ws.op==searchTasks affected_user==$ME_LINK
```

**Format the output nicely:**
```bash
# Simple list (title already includes bug number and context)
lp-api get people/+me ws.op==searchTasks assignee==$ME_LINK status=="In Progress" | \
  jq -r '.entries[].title'

# Or extract just bug number and description
lp-api get people/+me ws.op==searchTasks assignee==$ME_LINK status=="In Progress" | \
  jq -r '.entries[] | (.bug_link | split("/")[-1]) + ": " + (.title | split(": ")[1:] | join(": "))'
```

**Key Points:**
- The `assignee`, `bug_reporter`, `bug_subscriber`, `bug_commenter`, and `affected_user` parameters require the full API link (e.g., `https://api.launchpad.net/devel/~username`).
- Use `jq -r '.self_link'` to extract the link from a person resource.
- `bug_commenter` includes any bug activity (comments, status changes, field updates), not just message comments.
- Person-level `searchTasks` searches across **all contexts** (all projects and distributions).
- This is equivalent to the web UI at `https://launchpad.net/~username/+assignedbugs`.

### User's SSH Keys
SSH keys are not typically exposed via the standard API for security/privacy, but some public details might be available depending on permissions.

## Common Workflows

### 1. Check if User Exists
```bash
if lp-api get ~username > /dev/null 2>&1; then
  echo "User exists"
else
  echo "User not found"
fi
```

### 2. List My Teams
```bash
lp-api get people/+me | lp-api .memberships_collection_link | \
  jq -r '.entries[] | .team_link'
```
