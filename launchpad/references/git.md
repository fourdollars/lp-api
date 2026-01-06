# Launchpad Git & Recipes Reference

Launchpad hosts Git repositories and supports building packages from them using "Recipes".

## Resource Paths

### Git Repositories
Hosted git repositories for projects or distributions.

**Path:** `~<owner>/<project>/+git/<repo-name>`

Example: `~ubuntu-core-dev/ubuntu/+git/ubuntu-seeds`

### Git Branches (Refs)
Specific references within a repository.

**Path:** `~<owner>/<project>/+git/<repo-name>/+ref/<ref-name>`

### Recipes
Build recipes that define how to construct a package from a git branch.

**Path:** `~<owner>/<project>/+git/<repo-name>/recipes`

## Recipe Operations

### List Recipes
Get all recipes associated with a git repository.

```bash
lp-api get ~owner/project/+git/repo/recipes
```

### Create Recipe
Create a new git-build-recipe for automated package builds.

**Operation:** `createRecipe`
**Resource:** `~owner` (The person/team creating the recipe)

```bash
lp-api post ~owner \
  ws.op=createRecipe \
  name="my-recipe" \
  description="Daily build recipe" \
  distroseries="https://api.launchpad.net/devel/ubuntu/noble" \
  build_daily=true \
  daily_build_archive="https://api.launchpad.net/devel/~owner/+archive/ubuntu/ppa" \
  recipe_text="<recipe-content>"
```

**Recipe Text Format:**
```
# git-build-recipe format 0.4 deb-version {debversion}~{revtime}git{git-commit}
lp:~owner/project/+git/repo branch-name
```

### Trigger Build
Manually trigger a build for a recipe.

**Operation:** `performDailyBuild`
**Resource:** `<recipe-resource>`

```bash
lp-api post ~owner/+recipe/my-recipe ws.op=performDailyBuild
```

## Merge Proposals

### List Merge Proposals
Get merge proposals for a git repository.

```bash
lp-api get ~owner/project/+git/repo/+merge
```

### Get Merge Proposal Details
Get specific merge proposal information including diffs and comments.

```bash
lp-api get ~owner/project/+git/repo/+merge/<proposal-id>
```

### Add Comment to Merge Proposal
Add a review comment to a merge proposal.

**Operation:** `createComment`
**Resource:** `~owner/project/+git/repo/+merge/<proposal-id>`

```bash
lp-api post ~owner/project/+git/repo/+merge/<proposal-id> \
  ws.op=createComment \
  subject="Review feedback" \
  content="Detailed review comments and suggestions..."
```

**Parameters:**
- `subject`: Comment subject line
- `content`: Full comment content (supports markdown formatting)

### Get Merge Proposal Comments
List all comments on a merge proposal.

```bash
lp-api get ~owner/project/+git/repo/+merge/<proposal-id>/all_comments
```

### Get Preview Diff
View the diff for a merge proposal before merging.

```bash
lp-api get ~owner/project/+git/repo/+merge/<proposal-id>/+preview-diff/<diff-id>/diff_text
```

## Legacy Bazaar
Bazaar branches are accessed via: `~owner/project/branch-name`

```