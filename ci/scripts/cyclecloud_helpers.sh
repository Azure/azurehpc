#!/bin/bash

# Wait a cluster to reach it's target state
# TODO : Add timeout 
cluster_wait_targetstate()
{
    local cluster_name=$1
    local master_name=${2-master}

    state=$(cyclecloud show_nodes -c $cluster_name --format=json | jq -r --arg master "$master_name" '.[] | select(.Name==$master) | .State')
    target=$(cyclecloud show_nodes -c $cluster_name --format=json | jq -r --arg master "$master_name" '.[] | select(.Name==$master) | .TargetState')
    while [ "$state" != "$target" ]; do
        echo "Cluster $cluster_name status is $state waiting to reach $target"
        sleep 20
        state=$(cyclecloud show_nodes -c $cluster_name --format=json | jq -r --arg master "$master_name" '.[] | select(.Name==$master) | .State')
    done
}

get_master_name()
{
    local cluster_name=$1
    local master_name=${2-master}
    cyclecloud show_nodes -c $cluster_name --format=json | jq -r --arg master "$master_name" '.[] | select(.Name==$master) | .Instance.PrivateHostName'
}