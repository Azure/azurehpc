#!/bin/bash
export azhpc_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
source "$azhpc_dir/libexec/common.sh"
source "$azhpc_dir/libexec/install_helper.sh"

DEBUG_ON=0
COLOR_ON=1
config_file="config.json"

function usage() {
    echo "Command:"
    echo "    $0 [options] json_paths"
    echo
    echo "Arguments"
    echo "    -h --help  : diplay this help"
    echo "    -c --config: config file to use"
    echo "                 default: config.json"
    echo
}

while true; do
    case $1 in
        -h|--help)
        usage
        exit 0
        ;;
        -c|--config)
        config_file="$2"
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

while [[ $# -gt 0 ]]; do

    read_value val .$1

    echo "$1 = $val"
    shift

done