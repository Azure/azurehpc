#!/bin/bash
cluster_name=$1
cmd=$2

echo "Retrieving master name"
master=$(get_master_name $cluster_name)
echo "master is $master"

ssh $master "$cmd"
