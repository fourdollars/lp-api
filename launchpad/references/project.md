# Launchpad Project Reference

Projects (or Products) in Launchpad represent individual software projects like `firefox`, `cloud-init`, or `launchpad` itself.

## Resource Paths

### Project Resource
`<project-name>`

Example: `cloud-init`

### Project Milestones
`<project-name>/+milestones` or follow `all_milestones_collection_link`.

### Project Series
`<project-name>/<series-name>` or follow `series_collection_link`.

### Project Releases
`<project-name>/+releases` or follow `releases_collection_link`.

## Querying Projects

### Search for Projects
**Operation:** `search`
**Resource:** `projects`

```bash
lp-api get projects ws.op==search text=="cloud"
```

### List Latest Projects
**Operation:** `latest`
**Resource:** `projects`

```bash
lp-api get projects ws.op==latest
```

## Project Operations

### Create a New Project
**Operation:** `new_project`
**Resource:** `projects`

```bash
lp-api post projects \
  ws.op=new_project \
  name="my-new-project" \
  display_name="My New Project" \
  title="A Great Project" \
  summary="This project does amazing things."
```

### Manage Series
Create a new series for a project.

**Operation:** `newSeries`
**Resource:** `<project-name>`

```bash
lp-api post cloud-init \
  ws.op=newSeries \
  name="24.1" \
  summary="The 24.1 stable series"
```

### Manage Milestones
Get or create milestones for a project.

**Operation:** `getMilestone`
**Resource:** `<project-name>`

```bash
lp-api get cloud-init ws.op==getMilestone name=="24.1"
```

## Milestones and Releases

### Specific Milestone
`<project-name>/+milestone/<milestone-name>`

### Create a Release from Milestone
**Operation:** `createProductRelease`
**Resource:** `<project-name>/+milestone/<milestone-name>`

```bash
lp-api post cloud-init/+milestone/24.1 \
  ws.op=createProductRelease \
  date_released="2024-01-01"
```

## Project Metadata

Projects have many useful properties and links:
- `owner_link`: The person or team that owns the project.
- `driver_link`: The person or team that can set feature goals.
- `bug_tracker_link`: Link to the project's bug tracker.
- `official_bugs`: Whether Launchpad is the official bug tracker.
- `programming_language`: The primary language used.

## Common Workflows

### 1. Project Triage
Search for all active bugs across a project.

```bash
lp-api get <project-name> ws.op==searchTasks status==New
```

### 2. Milestone Management
List all milestones for a project to see upcoming targets.

```bash
lp-api get <project-name> | lp-api .all_milestones_collection_link | jq -r '.entries[].name'
```

