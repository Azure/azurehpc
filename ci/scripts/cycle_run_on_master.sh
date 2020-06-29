#!/bin/bash
cluster_name=$1
cmd="$2"

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$script_dir/cyclecloud_helpers.sh"

echo "Retrieving master name"
master=$(get_master_name $cluster_name)
echo "master is $master"

ssh $master "$cmd"
