#!/bin/bash
hostfile=$1
directory=${2:-/mnt/resource/beeond}

if [ "$PSSH_NODENUM" = "0" ]; then
    sudo beeond start -n $(readlink -f $hostfile) -d $directory -c /beeond
fi
