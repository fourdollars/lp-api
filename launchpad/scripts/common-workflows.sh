#!/bin/bash
# Common Launchpad API Workflow Functions
# Source this file to use these functions in your scripts

# Check if lp-api is available
if ! command -v lp-api &> /dev/null; then
    echo "Error: lp-api command not found. Install with: go install github.com/fourdollars/lp-api@latest"
    exit 1
fi

# ============================================================================
# BUG WORKFLOWS
# ============================================================================

# Get bug details in human-readable format
# Usage: lp_bug_info <bug-id>
lp_bug_info() {
    local bug_id=$1
    lp-api get "bugs/${bug_id}" | jq '{
        id: .id,
        title: .title,
        status: .status,
        importance: .importance,
        tags: .tags,
        created: .date_created,
        web_link: .web_link
    }'
}

# Search bugs with common filters
# Usage: lp_search_bugs <project> [status] [importance] [tags...]
lp_search_bugs() {
    local project=$1
    local status=${2:-""}
    local importance=${3:-""}
    shift 3
    local tags=("$@")
    
    local cmd="lp-api get $project ws.op==searchTasks"
    [ -n "$status" ] && cmd="$cmd status==$status"
    [ -n "$importance" ] && cmd="$cmd importance==$importance"
    
    for tag in "${tags[@]}"; do
        cmd="$cmd tags==$tag"
    done
    
    [ ${#tags[@]} -gt 1 ] && cmd="$cmd tags_combinator==All"
    
    eval "$cmd"
}

# Count bugs matching criteria
# Usage: lp_count_bugs <project> [status] [importance] [tags...]
lp_count_bugs() {
    local project=$1
    local status=${2:-""}
    local importance=${3:-""}
    shift 3
    local tags=("$@")
    
    local cmd="lp-api get $project ws.op==searchTasks ws.show==total_size"
    [ -n "$status" ] && cmd="$cmd status==$status"
    [ -n "$importance" ] && cmd="$cmd importance==$importance"
    
    for tag in "${tags[@]}"; do
        cmd="$cmd tags==$tag"
    done
    
    eval "$cmd"
}

# Add comment to bug
# Usage: lp_bug_comment <bug-id> <message>
lp_bug_comment() {
    local bug_id=$1
    local message=$2
    lp-api post "bugs/${bug_id}" ws.op=newMessage content="$message"
}

# Update bug tags
# Usage: lp_bug_update_tags <bug-id> <tag1> [tag2] [tag3]...
lp_bug_update_tags() {
    local bug_id=$1
    shift
    local tags=("$@")
    
    # Convert to JSON array
    local json_tags=$(printf '%s\n' "${tags[@]}" | jq -R . | jq -s .)
    
    lp-api patch "bugs/${bug_id}" "tags:=${json_tags}"
}

# Subscribe to bug
# Usage: lp_bug_subscribe <bug-id>
lp_bug_subscribe() {
    local bug_id=$1
    lp-api post "bugs/${bug_id}" ws.op=subscribe
}

# ============================================================================
# BUILD WORKFLOWS
# ============================================================================

# Get latest build for a livefs
# Usage: lp_latest_build <livefs-path>
# Example: lp_latest_build "~ubuntu-cdimage/+livefs/ubuntu/jammy/ubuntu"
lp_latest_build() {
    local livefs=$1
    lp-api get "$livefs" | \
        lp-api .builds_collection_link | \
        jq -r '.entries[0]'
}

# Get build status
# Usage: lp_build_status <build-resource-path>
lp_build_status() {
    local build=$1
    lp-api get "$build" | jq -r '.buildstate'
}

# Download all artifacts from a build
# Usage: lp_download_build_artifacts <build-resource-path>
lp_download_build_artifacts() {
    local build=$1
    
    echo "Getting artifact URLs for $build..."
    local urls=$(lp-api get "$build" ws.op==getFileUrls | jq -r '.[]')
    
    if [ -z "$urls" ]; then
        echo "No artifacts found for build"
        return 1
    fi
    
    echo "Downloading artifacts..."
    while IFS= read -r url; do
        echo "Downloading: $(basename "$url")"
        lp-api download "$url"
    done <<< "$urls"
}

# Wait for build to complete
# Usage: lp_wait_for_build <build-resource-path> [timeout-seconds]
lp_wait_for_build() {
    local build=$1
    local timeout=${2:-3600}  # Default 1 hour
    local elapsed=0
    local interval=30
    
    echo "Waiting for build to complete: $build"
    
    while [ $elapsed -lt $timeout ]; do
        local state=$(lp_build_status "$build")
        echo "[$elapsed s] Build state: $state"
        
        case "$state" in
            "Successfully built")
                echo "Build completed successfully!"
                return 0
                ;;
            "Failed to build"|"Cancelled build"|"Build for superseded Source")
                echo "Build failed with state: $state"
                return 1
                ;;
            *)
                sleep $interval
                elapsed=$((elapsed + interval))
                ;;
        esac
    done
    
    echo "Timeout waiting for build"
    return 1
}

# Get failed builds from livefs
# Usage: lp_failed_builds <livefs-path>
lp_failed_builds() {
    local livefs=$1
    lp-api get "$livefs" | \
        lp-api .builds_collection_link | \
        jq -r '.entries[] | select(.buildstate == "Failed to build") | .self_link'
}

# ============================================================================
# PACKAGE WORKFLOWS
# ============================================================================

# Get source package info
# Usage: lp_package_info <distro> <series> <package-name>
lp_package_info() {
    local distro=$1
    local series=$2
    local package=$3
    lp-api get "${distro}/${series}/+source/${package}"
}

# Search package bugs
# Usage: lp_package_bugs <distro> <package-name> [status]
lp_package_bugs() {
    local distro=$1
    local package=$2
    local status=${3:-""}
    
    local cmd="lp-api get ${distro}/+source/${package} ws.op==searchTasks"
    [ -n "$status" ] && cmd="$cmd status==$status"
    
    eval "$cmd"
}

# ============================================================================
# PPA WORKFLOWS
# ============================================================================

# List PPA packages
# Usage: lp_ppa_packages <owner> <ppa-name>
lp_ppa_packages() {
    local owner=$1
    local ppa=$2
    lp-api get "~${owner}/+archive/ubuntu/${ppa}" | \
        lp-api .published_sources_collection_link | \
        jq -r '.entries[] | "\(.source_package_name) \(.source_package_version)"'
}

# Copy package to PPA
# Usage: lp_ppa_copy_package <dest-owner> <dest-ppa> <source-name> <version> <from-archive> <to-series>
lp_ppa_copy_package() {
    local owner=$1
    local ppa=$2
    local pkg=$3
    local version=$4
    local from=$5
    local series=$6
    
    lp-api post "~${owner}/+archive/ubuntu/${ppa}" \
        ws.op=copyPackage \
        source_name="$pkg" \
        version="$version" \
        from_archive="$from" \
        to_pocket=Release \
        to_series="$series"
}

# ============================================================================
# PERSON/TEAM WORKFLOWS
# ============================================================================

# Get person info
# Usage: lp_person_info <username>
lp_person_info() {
    local username=$1
    lp-api get "~${username}" | jq '{
        name: .name,
        display_name: .display_name,
        karma: .karma,
        is_team: .is_team,
        web_link: .web_link
    }'
}

# Get team members
# Usage: lp_team_members <team-name>
lp_team_members() {
    local team=$1
    lp-api get "~${team}" | \
        lp-api .members_collection_link | \
        jq -r '.entries[] | .name'
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Follow a link field from piped JSON
# Usage: lp-api get resource | lp_follow_link <field-name>
lp_follow_link() {
    local field=$1
    lp-api ".${field}"
}

# Pretty print JSON from lp-api
# Usage: lp-api get resource | lp_pretty
lp_pretty() {
    jq '.'
}

# Extract web links from search results
# Usage: lp-api get project ws.op==searchTasks | lp_extract_web_links
lp_extract_web_links() {
    jq -r '.entries[] | .web_link'
}

# Extract all *_link fields from a resource
# Usage: lp-api get resource | lp_show_links
lp_show_links() {
    jq 'to_entries | .[] | select(.key | endswith("_link")) | {(.key): .value}'
}

# Paginate through all results
# Usage: lp_paginate_all <resource> <operation> [filters...]
lp_paginate_all() {
    local resource=$1
    local operation=$2
    shift 2
    local filters=("$@")
    
    local start=0
    local size=100
    local has_more=true
    
    while [ "$has_more" = true ]; do
        local cmd="lp-api get $resource ws.op==$operation ws.start==$start ws.size==$size"
        for filter in "${filters[@]}"; do
            cmd="$cmd $filter"
        done
        
        local result=$(eval "$cmd")
        local entries=$(echo "$result" | jq '.entries')
        local count=$(echo "$entries" | jq 'length')
        
        if [ "$count" -eq 0 ]; then
            has_more=false
        else
            echo "$entries" | jq -c '.[]'
            start=$((start + size))
        fi
    done
}

# ============================================================================
# EXAMPLE WORKFLOWS
# ============================================================================

# Example: Monitor builds for a livefs
example_monitor_builds() {
    local livefs="~ubuntu-cdimage/+livefs/ubuntu/jammy/ubuntu"
    
    echo "=== Latest Build ==="
    lp_latest_build "$livefs" | jq '{
        id: .id,
        state: .buildstate,
        started: .date_started,
        web_link: .web_link
    }'
    
    echo -e "\n=== Failed Builds ==="
    lp_failed_builds "$livefs"
}

# Example: Bug triage workflow
example_bug_triage() {
    local project="ubuntu"
    
    echo "=== High Priority Untriaged Bugs ==="
    lp_search_bugs "$project" "New" "High" | \
        lp_extract_web_links | head -10
    
    echo -e "\n=== Bug Count by Status ==="
    for status in "New" "Triaged" "In Progress" "Fix Committed"; do
        count=$(lp_count_bugs "$project" "$status")
        printf "%-15s: %d\n" "$status" "$count"
    done
}

# Example: Download latest Ubuntu artifacts
example_download_latest_ubuntu() {
    local livefs="~ubuntu-cdimage/+livefs/ubuntu/jammy/ubuntu"
    
    echo "Getting latest build..."
    local build_link=$(lp_latest_build "$livefs" | jq -r '.self_link')
    
    echo "Build: $build_link"
    
    local state=$(lp_build_status "$build_link")
    echo "State: $state"
    
    if [ "$state" = "Successfully built" ]; then
        lp_download_build_artifacts "$build_link"
    else
        echo "Build not ready for download"
        exit 1
    fi
}

# Print usage if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    cat << 'EOF'
Launchpad API Workflow Functions

Usage: source this file in your scripts

    source common-workflows.sh
    
Available Functions:

Bug Workflows:
  lp_bug_info <bug-id>
  lp_search_bugs <project> [status] [importance] [tags...]
  lp_count_bugs <project> [status] [importance] [tags...]
  lp_bug_comment <bug-id> <message>
  lp_bug_update_tags <bug-id> <tag1> [tag2]...
  lp_bug_subscribe <bug-id>

Build Workflows:
  lp_latest_build <livefs-path>
  lp_build_status <build-resource-path>
  lp_download_build_artifacts <build-resource-path>
  lp_wait_for_build <build-resource-path> [timeout-seconds]
  lp_failed_builds <livefs-path>

Package Workflows:
  lp_package_info <distro> <series> <package-name>
  lp_package_bugs <distro> <package-name> [status]

PPA Workflows:
  lp_ppa_packages <owner> <ppa-name>
  lp_ppa_copy_package <dest-owner> <dest-ppa> <source-name> <version> <from-archive> <to-series>

Person/Team Workflows:
  lp_person_info <username>
  lp_team_members <team-name>

Utility Functions:
  lp_follow_link <field-name>
  lp_pretty
  lp_extract_web_links
  lp_show_links
  lp_paginate_all <resource> <operation> [filters...]

Example Workflows:
  example_monitor_builds
  example_bug_triage
  example_download_latest_ubuntu

Examples:

  # Get info about a bug
  lp_bug_info 1

  # Search for high priority bugs with tags
  lp_search_bugs ubuntu "New" "High" focal jammy

  # Download artifacts from latest build
  lp_download_build_artifacts "~ubuntu-cdimage/+livefs/ubuntu/jammy/ubuntu/+build/12345"

  # Get team members
  lp_team_members ubuntu-core-dev

EOF
fi
