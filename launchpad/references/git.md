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

## Legacy Bazaar
Bazaar branches are accessed via: `~owner/project/branch-name`

```