#!/bin/bash
hostfile=$1
directory=${2:-/mnt/resource/beeond}
metadata=${3:-1}

if [ "$PSSH_NODENUM" = "0" ]; then
    sudo beeond start -F -P -n $(readlink -f $hostfile) -m $metadata -d $directory -c /beeond

    echo "Check if all nodes are connected thru RDMA"
    fallback_nodes=$(beegfs-net | grep fallback -A1 -B1)
    if [ -n "$fallback_nodes" ]; then
        echo "some nodes are unable to connect thru RDMA and fallback to TCP - exiting"
        echo $fallback_nodes
        exit 1
    fi
fi
