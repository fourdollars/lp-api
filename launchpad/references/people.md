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

### User's Assigned Bugs
`~username` (via bug search)

```bash
lp-api get ubuntu ws.op==searchTasks assignee==~username
```

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
