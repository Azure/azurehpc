#!/bin/bash
hostfile=$1
directory=${2:-/mnt/resource/beeond}
metadata=${3:-1}

if [ "$PSSH_NODENUM" = "0" ]; then
    sudo beeond start -q -F -P -n $(readlink -f $hostfile) -m $metadata -d $directory -c /beeond
fi
