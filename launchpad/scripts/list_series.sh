#!/bin/bash
# Script to list series for a given Launchpad project/distribution
# Usage: ./list_series.sh [project-name]
# Default: ubuntu

PROJECT=${1:-ubuntu}

echo "Listing series for $PROJECT..."
echo "Format: name: display_name (status)"
echo

lp-api get "$PROJECT" | lp-api .series_collection_link | \
  jq -r '.entries[] | "\(.name): \(.displayname) (\(.status))"'