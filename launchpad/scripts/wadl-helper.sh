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
            xmllint --xpath 'string-join(//wadl:method/@name, "\n")' --nonet --shell "$WADL_PATH" 2>/dev/null || \
            xmlstarlet sel -N wadl="http://research.sun.com/wadl/2006/10" -t -m "//wadl:method" -v "@name" -n "$WADL_PATH"
        else
            # list methods for a given resource_type id
            xmlstarlet sel -N wadl="http://research.sun.com/wadl/2006/10" -t -m "//wadl:resource_type[@id='$2']/wadl:method" -v "@name" -n "$WADL_PATH"
        fi
        ;;
    show-resource)
        if [ -z "$2" ]; then
            echo "Usage: $0 show-resource <resource_type_id>" >&2
            exit 2
        fi
        xmlstarlet sel -N wadl="http://research.sun.com/wadl/2006/10" -t -c "//wadl:resource_type[@id='$2']" "$WADL_PATH"
        ;;
    *)
        echo "Usage: $0 {list-methods [resource_type_id]|show-resource <resource_type_id>}"
        exit 2
        ;;
esac
