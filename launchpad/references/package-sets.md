# Launchpad Package Sets Reference

Package sets allow grouping source packages together. They are primarily used for managing access control (upload permissions) and for grouping packages for other administrative purposes in Ubuntu and other distributions.

## Resource Paths

The main entry point for package sets is:
`package-sets`

Individual package sets are often addressed by:
`package-sets/<distro>/<series>/<name>`

Example: `package-sets/ubuntu/jammy/canonical-oem-metapackages`

## Listing Package Sets

To list package sets, you typically need to scope the query to a specific distribution series (e.g., Ubuntu Noble).

**Operation:** `getBySeries`
**Resource:** `package-sets`

```bash
# List all package sets for Ubuntu Noble
lp-api get package-sets \
  ws.op==getBySeries \
  distroseries=="https://api.launchpad.net/devel/ubuntu/noble" | \
  jq -r '.entries[] | "\(.name): \(.description)"'
```

## Querying Package Sets

### Get Sources Included

List all source packages that are part of a package set.

**Operation:** `getSourcesIncluded`
**Resource:** `package-sets/<distro>/<series>/<name>`

```bash
# Get sources in the OEM metapackages set
lp-api get package-sets/ubuntu/jammy/canonical-oem-metapackages \
  ws.op==getSourcesIncluded | \
  jq -r '.entries[]'
```

### Find Sets Including a Source

Find which package sets contain a specific source package.

**Operation:** `setsIncludingSource`
**Resource:** `package-sets`

```bash
# Find sets containing linux-firmware in Jammy
lp-api get package-sets \
  ws.op==setsIncludingSource \
  sourcepackagename=="linux-firmware" \
  distroseries=="https://api.launchpad.net/devel/ubuntu/jammy" | \
  jq -r '.entries[] | .name'
```

### Get By Name

Get a specific package set if you know its name and series.

**Operation:** `getByName`
**Resource:** `package-sets`

```bash
lp-api get package-sets \
  ws.op==getByName \
  name=="canonical-oem-metapackages" \
  distroseries=="https://api.launchpad.net/devel/ubuntu/jammy"
```

## Creating Package Sets

**Operation:** `new`
**Resource:** `package-sets`

```bash
# Create a new package set
lp-api post package-sets \
  ws.op=new \
  name="my-package-set" \
  description="My custom package set" \
  owner="~my-team" \
  distroseries="https://api.launchpad.net/devel/ubuntu/noble"
```
