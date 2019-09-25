#!/bin/bash

hostfile=$1

if [ "$PSSH_NODENUM" = "0" ]; then
    sudo beeond start -n $(readlink -f $hostfile) -d /mnt/resource/beeond -c /beeond
fi
