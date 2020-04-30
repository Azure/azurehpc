#!/bin/bash
set -e
mounts=$1

check_mountpoint()
{
    local mount=$1
    if [ -d $mount ]; then
        echo "$mount exists"
        df -h $mount
        ls -al $mount
    else
        echo "$mount is missing"
        exit 1
    fi
}

for mount in $mounts; do
    check_mountpoint $mount
done