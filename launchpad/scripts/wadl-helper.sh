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
  template <id> <ws.op>       Print a detailed lp-api command template for resource and ws.op
  examples <id>               Print ready-to-run example commands for resource's ws.op values
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
        # generate a detailed lp-api command template for a resource and ws.op
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "Usage: $0 template <resource_type_id> <ws.op>" >&2
            exit 2
        fi
        resource_id=$2
        wsop=$3
        # extract params within the resource_type block that are mentioned for this ws.op
        block=$(awk "/<wadl:resource_type [^>]*id=\"$resource_id\"/, /<\/wadl:resource_type>/" "$WADL_PATH")
        # params in the block
        params=$(echo "$block" | grep -oP '<wadl:param[^>]*name="\K[^"]+' | sort -u)
        # required params detection: look for "required=\"true\""
        required=$(echo "$block" | grep -oP '<wadl:param[^>]*required="\Ktrue(?=")' >/dev/null && echo "" )
        echo "# lp-api template for resource: $resource_id ws.op=$wsop"
        echo "# Detected params: $params"
        # Build a command depending on HTTP verb for common ws.op patterns
        verb="post"
        if echo "$block" | grep -q "ws.op==${wsop}"; then
            # heuristic: create operations are POST
            verb="post"
        fi
        echo "# Example command pattern:"
        cmd="lp-api $verb $resource_id ws.op==${wsop}"
        # append placeholder params
        for p in $params; do
            case "$p" in
                title|description|target|comment|filename)
                    cmd="$cmd $p=\"<$p>\""
                    ;;
                tags)
                    cmd="$cmd tags==\"tag1 tag2\""
                    ;;
                ws.op)
                    ;;
                *)
                    cmd="$cmd $p=\"<$p>\""
                    ;;
            esac
        done
        echo "$cmd"
        ;;
    examples)
        # print ready-to-run example commands for common ws.ops of a resource
        if [ -z "$2" ]; then
            echo "Usage: $0 examples <resource_type_id>" >&2
            exit 2
        fi
        rid=$2
        echo "# Examples for resource: $rid"
        # list ws.ops
        wsops=$(awk "/<wadl:resource_type [^>]*id=\"$rid\"/, /<\/wadl:resource_type>/" "$WADL_PATH" | grep -oP 'name="ws.op"[^>]*fixed="\K[^"]+' | sort -u)
        if [ -z "$wsops" ]; then
            echo "No ws.op values found for $rid"
            exit 0
        fi
        for op in $wsops; do
            echo -e "\n# ws.op=$op"
            "$0" template "$rid" "$op" || true
            # provide a concrete example for common ops
            case "$op" in
                createBug)
                    echo "# Concrete example:"
                    echo "lp-api post $rid ws.op==createBug title=\"Example bug\" description=\"Steps to reproduce...\" target=\"ubuntu\" tags==\"example\""
                    ;;
                searchTasks)
                    echo "# Concrete example:"
                    echo "lp-api get ubuntu ws.op==searchTasks tags==jammy status==New"
                    ;;
                *)
                    echo "# No specialized concrete example for $op"
                    ;;
            esac
        done
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
