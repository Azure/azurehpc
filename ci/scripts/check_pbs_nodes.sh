#!/bin/bash
nodes=$1
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$script_dir/common.sh"
source "$script_dir/pbs_helpers.sh"

list_nodes
avail_nodes=$(get_node_count)

if [ "$avail_nodes" != "$nodes" ]; then
    echo "number of available nodes ($avail_nodes) is different from expected ($nodes)"
    exit 1
fi

