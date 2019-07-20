#!/bin/bash
export azhpc_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
source "$azhpc_dir/libexec/common.sh"

DEBUG_ON=0
COLOR_ON=1
config_file="config.json"

function usage() {
    echo "Command:"
    echo "    $0 [options]"
    echo
    echo "Arguments"
    echo "    -h --help  : diplay this help"
    echo "    -c --config: config file to use"
    echo "                 default: config.json"
    echo "    -u --update: update time in seconds"
    echo "                 Use 0 for no updates"
    echo "                 default: 0"
    echo
}

update=0

while true; do
    case $1 in
        -h|--help)
        usage
        exit 0
        ;;
        -c|--config)
        config_path="$2"
        shift
        shift
        ;;
        -u|--update)
        update="$2"
        shift
        shift
        ;;
        *)
        break
    esac
done

if [ ! -f "$config_file" ]; then
    error "missing config file ($config_file)"
fi

read_value resource_group ".resource_group"

while true; do

    output=()

    for resource_name in $(jq -r ".resources | keys | @tsv" $config_file); do

        read_value resource_type ".resources.$resource_name.type"

        case $resource_type in
            vm)
                output+=($resource_name "$( \
                    az vm show \
                        --resource-group $resource_group \
                        --name $resource_name \
                        --query provisioningState \
                        --output tsv 2>/dev/null \
                        | sort | uniq -c \
                        | sed 's/^ */ /g' | tr '\n' ',' | sed 's/,$/ /g' \
                    )")
            ;;
            vmss)
                output+=($resource_name "$( \
                    az vmss list-instances \
                        --resource-group $resource_group \
                        --name $resource_name \
                        --query [].provisioningState \
                        --output tsv 2>/dev/null \
                        | sort | uniq -c \
                        | sed 's/^ */ /g' | tr '\n' ',' | sed 's/,$/ /g' \
                    )")
            ;;
            *)
                error "unknown resource type ($resource_type) for $resource_name"
            ;;
        esac
    done

    if [ "$update" != "0" ]; then
        clear
        printf "Provising Status [$resource_group]\n\n"
    fi

    printf '%-15s %s\n' "${output[@]}"

    if [ "$update" = "0" ]; then
        break
    fi

    sleep $update
done
