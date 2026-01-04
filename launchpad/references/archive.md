# Launchpad Archive Reference

Archives in Launchpad represent repositories of packages. This includes the primary archive for distributions (like Ubuntu) and Personal Package Archives (PPAs).

## Resource Paths

### Primary Archive
The main repository for a distribution.
`ubuntu/+archive/primary`
`debian/+archive/primary`

### PPAs (Personal Package Archives)
Repositories owned by individuals or teams.
`~<owner>/+archive/ubuntu/<ppa-name>`

Example: `~mozillateam/+archive/ubuntu/ppa`

## Querying Packages in Archives

### List Published Source Packages
**Operation:** `getPublishedSources`

```bash
# List published sources in a PPA for a specific series
lp-api get ~owner/+archive/ubuntu/ppa \
  ws.op==getPublishedSources \
  distro_series=="https://api.launchpad.net/devel/ubuntu/noble" \
  status==Published
```

### List Published Binary Packages
**Operation:** `getPublishedBinaries`

```bash
# List published binaries for a specific architecture
lp-api get ubuntu/+archive/primary \
  ws.op==getPublishedBinaries \
  distro_arch_series=="https://api.launchpad.net/devel/ubuntu/noble/amd64" \
  binary_name=="linux-image-generic" \
  exact_match==true
```

## Archive Operations

### Copying Packages
Move or copy a package from one archive to another (e.g., from primary to PPA, or between PPAs).

**Operation:** `copyPackage`

```bash
lp-api post ~dest-owner/+archive/ubuntu/dest-ppa \
  ws.op=copyPackage \
  source_name="my-package" \
  version="1.0-1" \
  from_archive="https://api.launchpad.net/devel/ubuntu/+archive/primary" \
  to_pocket=Release \
  to_series="noble"
```

### Syncing Source Packages
Sync a source package from the primary archive.

**Operation:** `syncSource`

```bash
lp-api post ~owner/+archive/ubuntu/ppa \
  ws.op=syncSource \
  source_name="vim" \
  to_pocket=Release \
  to_series="jammy"
```

### Deleting Packages
Remove a package from an archive.

**Operation:** `deletePackage`

```bash
lp-api post ~owner/+archive/ubuntu/ppa \
  ws.op=deletePackage \
  source_name="my-package" \
  distro_series="https://api.launchpad.net/devel/ubuntu/noble" \
  pocket=Release
```

## Archive Metadata

### PPA Signing Key
Get the public GPG key for a PPA.
`~owner/+archive/ubuntu/ppa/+signing-key`

### PPA Packages Collection
`~owner/+archive/ubuntu/ppa/+packages`

## Common Workflows

### 1. Check Package Availability
Verify if a specific version of a package is published in an archive.

```bash
lp-api get ubuntu/+archive/primary \
  ws.op==getPublishedSources \
  source_name=="linux" \
  version=="6.8.0-48.48" \
  status==Published
```

### 2. PPA Maintenance
List all packages in a PPA to identify old versions for cleanup.

```bash
lp-api get ~my-team/+archive/ubuntu/my-ppa | \
  lp-api .published_sources_collection_link | \
  jq -r '.entries[] | "\(.source_package_name) \(.source_package_version)"'
```
