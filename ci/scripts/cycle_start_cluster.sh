#!/bin/bash
cluster_name=$1
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$script_dir/cyclecloud_helpers.sh"

echo "Starting cluster '$cluster_name'"
cyclecloud start_cluster $cluster_name

echo "Waiting for cluster '$cluster_name' to be ready"
cluster_wait_targetstate $cluster_name

echo "Retrieving master name"
master=$(get_master_name $cluster_name)
echo "master is $master"

# echo "Changing ownership of shared scripts"
# ssh $master "sudo chown -R hpcadmin:hpcadmin /nfsshare/apps"
