#!/bin/bash
# Simple helper to query the bundled launchpad WADL for supported operations
# Usage: wadl-helper.sh list-methods [resource_type_id]

WADL_PATH="$(dirname "${BASH_SOURCE[0]}")/../assets/launchpad-wadl.xml"
if [ ! -f "$WADL_PATH" ]; then
    echo "WADL not found: $WADL_PATH" >&2
    exit 1
fi

# If no args provided, show help
if [ "$#" -eq 0 ]; then
    set -- -h
fi

case "$1" in
    -h|--help|help)
        cat <<'USAGE'
Usage: wadl-helper.sh <command> [args]

Commands:
  list-methods [resource]      List method names (optionally for a resource)
      Example: wadl-helper.sh list-methods bugs
  list-resources               List resource_type ids
      Example: wadl-helper.sh list-resources
  resource-methods <id>        List methods for resource_type id
      Example: wadl-helper.sh resource-methods bugs
  resource-params <id>         List parameter names for resource_type id
      Example: wadl-helper.sh resource-params bugs
  resource-wsops <id>         List ws.op fixed values for resource_type id
      Example: wadl-helper.sh resource-wsops bugs
  describe <id>               Show comprehensive info for a resource_type (methods, ws.ops, params with required/docs)
      Example: wadl-helper.sh describe bugs
  template <id> <ws.op>       Print a detailed lp-api command template for resource and ws.op
      Example: wadl-helper.sh template bugs createBug
  examples <id>               Print ready-to-run example commands for resource's ws.op values
      Example: wadl-helper.sh examples bugs
  show-resource <id>          Print the raw WADL section for resource_type id
      Example: wadl-helper.sh show-resource bugs
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
    describe)
        if [ -z "$2" ]; then
            echo "Usage: $0 describe <resource_type_id>" >&2
            exit 2
        fi
        rid=$2
        block=$(awk "/<wadl:resource_type [^>]*id=\"$rid\"/, /<\/wadl:resource_type>/" "$WADL_PATH")
        if [ -z "$block" ]; then
            echo "Resource not found: $rid" >&2
            exit 1
        fi

        echo "Resource: $rid"
        echo
        echo "Methods:"
        echo "$block" | grep -oP '<wadl:method[^>]*name="\K[^"]+' | sort -u | sed -e 's/^/  - /' || true
        echo
        echo "ws.op values:"
        echo "$block" | grep -oP 'name="ws.op"[^>]*fixed="\K[^"]+' | sort -u | sed -e 's/^/  - /' || true
        echo
        # Show parameters specific to each ws.op
        # For each ws.op, show methods and parameters with docs
        wsops=$(echo "$block" | grep -oP 'name="ws.op"[^>]*fixed="\\K[^"]+' | sort -u)
        if [ -n "$wsops" ]; then
            for op in $wsops; do
                echo "ws.op = $op"
                # try to find method(s) that reference this op
                methods=$(echo "$block" | grep -oP "<wadl:method[^>]*>[^<]*<.*ws.op.*${op}.*|<wadl:method[^>]*name=\"\K[^"]+" | sort -u || true)
                # fallback to methods in resource
                if [ -z "$methods" ]; then
                    methods=$(echo "$block" | grep -oP "<wadl:method[^>]*name=\"\K[^"]+" | sort -u)
                fi
                echo "  Methods: $(echo "$methods" | tr '\n' ' ' )"

                # extract params from request blocks that contain this ws.op
                reqs=$(echo "$block" | awk -v op="$op" 'BEGIN{RS="<wadl:request"; ORS=""} $0 ~ op {print "<wadl:request" $0}' )
                if [ -n "$reqs" ]; then
                    # for each param in reqs, show detailed info
                    echo "$reqs" | grep -oP '<wadl:param[^>]*name="\K[^"]+' | sort -u | while read -r pname; do
                        # reuse param extraction from full block
                        paramtag=$(echo "$block" | grep -oP "<wadl:param[^>]*name=\"$pname\"[^>]*>" | head -n1)
                        required=$(echo "$paramtag" | grep -oP 'required="\K[^"]+' || true)
                        section=$(sed -n "/<wadl:param[^>]*name=\"$pname\"/,/<\/wadl:param>/p" <(echo "$block") | tr '\n' ' ')
                        doc=$(echo "$section" | grep -oP '<wadl:doc[^>]*>\K.*?(?=</wadl:doc>)' || true)
                        doc=$(echo "$doc" | sed 's/<[^>]*>//g' | tr -s ' ' ' ' | sed 's/^ *//;s/ *$//')
                        if [ -z "$required" ]; then
                            label="optional"
                        else
                            if [ "$required" = "true" ]; then
                                label="mandatory"
                            else
                                label="optional"
                            fi
                        fi
                        if [ -n "$doc" ]; then
                            echo "  - $pname [$label]"
                            echo "      $doc"
                        else
                            echo "  - $pname [$label]"
                        fi
                    done
                else
                    echo "  (no ws.op-specific parameters)"
                fi
                echo
            done
        fi

        echo "Parameters (name [required?] - doc):"
        tmp=$(mktemp)
        echo "$block" > "$tmp"
        params=$(grep -oP '<wadl:param[^>]*name="\K[^"]+' "$tmp" | sort -u)
        for name in $params; do
            paramtag=$(grep -oP "<wadl:param[^>]*name=\"$name\"[^>]*>" "$tmp" | head -n1)
            required=$(echo "$paramtag" | grep -oP 'required="\K[^"]+' || true)
            # flatten the param section and extract wadl:doc content if present
            section=$(sed -n "/<wadl:param[^>]*name=\"$name\"/,/<\/wadl:param>/p" "$tmp" | tr '\n' ' ')
            doc=$(echo "$section" | grep -oP '<wadl:doc[^>]*>\K.*?(?=</wadl:doc>)' || true)
            doc=$(echo "$doc" | sed 's/<[^>]*>//g' | tr -s ' ' ' ' | sed 's/^ *//;s/ *$//')
            if [ -z "$required" ]; then
                label="optional"
            else
                if [ "$required" = "true" ]; then
                    label="mandatory"
                else
                    label="optional"
                fi
            fi
            if [ -n "$doc" ]; then
                echo "  - $name [$label]"
                # indent doc on next line
                echo "      $doc"
            else
                echo "  - $name [$label]"
            fi
        done
        rm -f "$tmp"
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
