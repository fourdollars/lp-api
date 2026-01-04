# Launchpad LiveFS Reference

Live Filesystems (LiveFS) are used to build ISO images and other live system artifacts (like Ubuntu desktop and server images).

## Resource Paths

### LiveFS Configuration
The configuration for a specific live system image build.
`~owner/+livefs/<distro>/<series>/<name>`

Example: `~ubuntu-cdimage/+livefs/ubuntu/noble/ubuntu`

### LiveFS Builds Collection
Access builds for a specific LiveFS configuration.
`~owner/+livefs/<distro>/<series>/<name> | .builds_collection_link`

Common filterable collections:
- `completed_builds_collection_link`
- `pending_builds_collection_link`

### Specific Build
`~owner/+livefs/<distro>/<series>/<name>/+build/<build-id>`

## Monitoring Builds

### Get Build Status
Retrieve the current state of a build.

```bash
lp-api get ~owner/+livefs/ubuntu/noble/ubuntu/+build/12345 | jq -r '.buildstate'
```

Common build states:
- `Successfully built`
- `Failed to build`
- `Building`
- `Needs building`
- `Cancelled build`

### List Recent Builds
```bash
lp-api get ~ubuntu-cdimage/+livefs/ubuntu/noble/ubuntu | \
  lp-api .builds_collection_link | \
  jq -r '.entries[] | "\(.id): \(.buildstate) (\(.date_started))"'
```

## Build Artifacts

### Get Download URLs
Retrieve URLs for all files produced by a build (ISO images, manifest files, etc.).

**Operation:** `getFileUrls` (supported on build resources)

```bash
lp-api get ~owner/+livefs/ubuntu/noble/ubuntu/+build/12345 \
  ws.op==getFileUrls | jq -r '.[]'
```

### Download Artifacts
```bash
lp-api get <build-resource> ws.op==getFileUrls | \
  jq -r '.[]' | \
  xargs -I {} lp-api download {}
```

## Build Control

### Retry a Failed Build
**Operation:** `retry`

```bash
lp-api post ~owner/+livefs/ubuntu/noble/ubuntu/+build/12345 ws.op=retry
```

### Cancel a Pending Build
**Operation:** `cancel`

```bash
lp-api post ~owner/+livefs/ubuntu/noble/ubuntu/+build/12345 ws.op=cancel
```

## Common Workflows

### 1. Wait for Build Completion
Poll a build until it finishes.

```bash
# Using the helper function from common-workflows.sh
lp_wait_for_build "~ubuntu-cdimage/+livefs/ubuntu/noble/ubuntu/+build/12345"
```

### 2. Identify Failed Builds
Find builds that failed to identify issues in the build environment or configuration.

```bash
lp-api get ~ubuntu-cdimage/+livefs/ubuntu/noble/ubuntu | \
  lp-api .builds_collection_link | \
  jq -r '.entries[] | select(.buildstate == "Failed to build") | .web_link'
```

