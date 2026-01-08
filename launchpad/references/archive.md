# Launchpad Archive Reference

Archives in Launchpad represent repositories of packages. This includes the primary archive for distributions (like Ubuntu) and Personal Package Archives (PPAs).

## Resource Paths

### Primary Archive
The main repository for a distribution.
- `ubuntu/+archive/primary`
- `debian/+archive/primary`

### PPAs (Personal Package Archives)
Repositories owned by individuals or teams.
- `~<owner>/+archive/ubuntu/<ppa-name>`

Example: `~ubuntu-wine/+archive/ubuntu/ppa`

## Querying Packages in Archives

When querying packages using `getPublishedSources` or `getPublishedBinaries`, **ALWAYS** check the total size first using `ws.show==total_size`. This returns a **plain text integer number**.

### List Published Source Packages
**Operation:** `getPublishedSources`

```bash
# 1. Check total count (returns plain text integer)
lp-api get ~ubuntu-wine/+archive/ubuntu/ppa \
  ws.op==getPublishedSources \
  distro_series=="https://api.launchpad.net/devel/ubuntu/noble" \
  status==Published \
  ws.show==total_size

# 2. Fetch results if count is reasonable
lp-api get ~ubuntu-wine/+archive/ubuntu/ppa \
  ws.op==getPublishedSources \
  distro_series=="https://api.launchpad.net/devel/ubuntu/noble" \
  status==Published
```

### List Published Binary Packages
**Operation:** `getPublishedBinaries`

```bash
# 1. Check total count (returns plain text integer)
lp-api get ubuntu/+archive/primary \
  ws.op==getPublishedBinaries \
  distro_arch_series=="https://api.launchpad.net/devel/ubuntu/noble/amd64" \
  binary_name=="linux-image-generic" \
  exact_match==true \
  ws.show==total_size

# 2. Fetch results if count is reasonable
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

**Operation:** `syncSource` (Note: `copyPackage` is generally preferred)

```bash
lp-api post ~owner/+archive/ubuntu/ppa \
  ws.op=syncSource \
  source_name="vim" \
  to_pocket=Release \
  to_series="jammy"
```

### Deleting Packages
Remove a package from an archive.

**Operation:** `requestDeletion` (Operates on a publication resource)

```bash
# Get the publication link first, then delete
lp-api post <publication-link> ws.op=requestDeletion removal_comment="Obsolete version"
```

## Archive Metadata

### PPA Signing Key
Get the public GPG key data for a PPA.

**Operation:** `getSigningKeyData`
```bash
lp-api get ~ubuntu-wine/+archive/ubuntu/ppa ws.op==getSigningKeyData
```

### PPA Packages Collection
View the package list for a PPA.
`~owner/+archive/ubuntu/ppa/+packages`

## Common Workflows

### 1. Check Package Availability
Verify if a specific version of a package is published in an archive.

```bash
# Check if count is > 0 (returns plain text integer)
lp-api get ubuntu/+archive/primary \
  ws.op==getPublishedSources \
  source_name=="linux" \
  version=="6.8.0-48.48" \
  status==Published \
  ws.show==total_size
```

### 2. PPA Maintenance
List recent publications in a PPA.

```bash
lp-api get ~ubuntu-wine/+archive/ubuntu/ppa \
  ws.op==getPublishedSources \
  order_by_date==true \
  ws.size==10 | jq -r '.entries[] | "\(.source_package_name) \(.source_package_version)"'
```