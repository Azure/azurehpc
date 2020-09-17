#!/bin/bash

zpool list

zpool iostat -v

if [ "$(zpool list | grep ONLINE | wc -l)" = "0" ]; then
    echo "Error: no ZFS pools are online"
    exit 1
fi
