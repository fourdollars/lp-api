#!/bin/bash
# Simple helper to query the bundled launchpad WADL for supported operations
# Usage: wadl-helper.sh list-methods [resource_type_id]

WADL_PATH="$(dirname "${BASH_SOURCE[0]}")/../assets/launchpad-wadl.xml"
if [ ! -f "$WADL_PATH" ]; then
    echo "WADL not found: $WADL_PATH" >&2
    exit 1
fi

case "$1" in
    list-methods)
        if [ -z "$2" ]; then
            # list all method names
            if command -v xmllint >/dev/null 2>&1; then
                xmllint --xpath 'string(//wadl:application//@*)' "$WADL_PATH" 2>/dev/null || true
            else
                # Fallback: grep for method name attributes
                grep -oP '<wadl:method[^>]*name="\K[^"]+' "$WADL_PATH" | sort -u
            fi
        else
            # list methods for a given resource_type id
            if command -v xmllint >/dev/null 2>&1; then
                xmllint --xpath "//wadl:resource_type[@id='$2']//wadl:method/@name" --nonet "$WADL_PATH" 2>/dev/null | sed -e 's/name="/\n/g' -e 's/"//g' | sed '/^$/d'
            else
                # Fallback: crude grep within resource_type block
                awk "/<wadl:resource_type [^>]*id=\"$2\"/, /<\/wadl:resource_type>/" "$WADL_PATH" | grep -oP '<wadl:method[^>]*name="\K[^"]+' | sort -u
            fi
        fi
        ;;
    show-resource)
        if [ -z "$2" ]; then
            echo "Usage: $0 show-resource <resource_type_id>" >&2
            exit 2
        fi
        if command -v xmllint >/dev/null 2>&1; then
            xmllint --format "$WADL_PATH" | awk "/<wadl:resource_type [^>]*id=\"$2\"/, /<\/wadl:resource_type>/"
        else
            awk "/<wadl:resource_type [^>]*id=\"$2\"/, /<\/wadl:resource_type>/" "$WADL_PATH"
        fi
        ;;
    *)
        echo "Usage: $0 {list-methods [resource_type_id]|show-resource <resource_type_id>}"
        exit 2
        ;;
esac
