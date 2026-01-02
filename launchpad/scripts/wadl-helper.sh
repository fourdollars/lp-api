#!/bin/bash
# Simple helper to query the bundled launchpad WADL for supported operations
# Usage: wadl-helper.sh list-methods [resource_type_id]

WADL_PATH="$(dirname "${BASH_SOURCE[0]}")/../assets/launchpad-wadl.xml"
if [ ! -f "$WADL_PATH" ]; then
    echo "WADL not found: $WADL_PATH" >&2
    exit 1
fi

case "$1" in
    -h|--help|help)
        cat <<'USAGE'
Usage: wadl-helper.sh <command> [args]

Commands:
  list-methods [resource]      List method names (optionally for a resource)
  list-resources               List resource_type ids
  resource-methods <id>        List methods for resource_type id
  resource-params <id>         List parameter names for resource_type id
  resource-wsops <id>         List ws.op fixed values for resource_type id
  template <id> <ws.op>       Print a basic lp-api command template for resource and ws.op
  show-resource <id>          Print the raw WADL section for resource_type id
  -h, --help                  Show this help
USAGE
        exit 0
        ;;
    list-methods)
        if [ -z "$2" ]; then
            # list all method names
            grep -oP '<wadl:method[^>]*name="\K[^"]+' "$WADL_PATH" | sort -u
        else
            # list methods for a given resource_type id
            awk "/<wadl:resource_type [^>]*id=\"$2\"/, /<\/wadl:resource_type>/" "$WADL_PATH" | grep -oP '<wadl:method[^>]*name="\K[^"]+' | sort -u
        fi
        ;;
    list-resources)
        # list resource_type ids
        grep -oP '<wadl:resource_type[^>]*id="\K[^"]+' "$WADL_PATH" | sort -u
        ;;
    resource-methods)
        if [ -z "$2" ]; then
            echo "Usage: $0 resource-methods <resource_type_id>" >&2
            exit 2
        fi
        awk "/<wadl:resource_type [^>]*id=\"$2\"/, /<\/wadl:resource_type>/" "$WADL_PATH" | grep -oP '<wadl:method[^>]*name="\K[^"]+' | sort -u
        ;;
    resource-params)
        if [ -z "$2" ]; then
            echo "Usage: $0 resource-params <resource_type_id>" >&2
            exit 2
        fi
        awk "/<wadl:resource_type [^>]*id=\"$2\"/, /<\/wadl:resource_type>/" "$WADL_PATH" | grep -oP '<wadl:param[^>]*name="\K[^"]+' | sort -u
        ;;
    resource-wsops)
        if [ -z "$2" ]; then
            echo "Usage: $0 resource-wsops <resource_type_id>" >&2
            exit 2
        fi
        awk "/<wadl:resource_type [^>]*id=\"$2\"/, /<\/wadl:resource_type>/" "$WADL_PATH" | grep -oP 'name="ws.op"[^>]*fixed="\K[^"]+' | sort -u
        ;;
    template)
        # generate a basic lp-api command template for a resource and ws.op
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "Usage: $0 template <resource_type_id> <ws.op>" >&2
            exit 2
        fi
        resource_id=$2
        wsop=$3
        # try to infer common path (resource id often equals collection name)
        # list params for this ws.op
        params=$(awk "/<wadl:resource_type [^>]*id=\"$resource_id\"/, /<\/wadl:resource_type>/" "$WADL_PATH" | grep -oP "<wadl:request[\s\S]*?ws.op=\.*$wsop[^"]*|<wadl:param[^>]*name=\"\K[^"]+" | tr '\n' ' ')
        echo "# lp-api template for resource: $resource_id ws.op=$wsop"
        # basic guess for resource path
        echo "# Example: lp-api post $resource_id ws.op==$wsop [params...]"
        ;;
    show-resource)
        if [ -z "$2" ]; then
            echo "Usage: $0 show-resource <resource_type_id>" >&2
            exit 2
        fi
        awk "/<wadl:resource_type [^>]*id=\"$2\"/, /<\/wadl:resource_type>/" "$WADL_PATH"
        ;;
    *)
        echo "Usage: $0 {list-methods [resource_type_id]|show-resource <resource_type_id>}"
        exit 2
        ;;
esac
