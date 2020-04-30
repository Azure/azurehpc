#!/bin/bash
mounts=$1

for mount in $mounts; do
    check_mountpoint $mount
done

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