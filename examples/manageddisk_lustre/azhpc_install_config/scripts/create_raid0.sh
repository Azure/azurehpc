#!/bin/bash

# arg: $1 = raid_device (e.g. /dev/md10)
# arg: $* = devices to use (can use globbing)

raid_device=$1
shift

devices=
while (( "$#" )); do
    devices="$devices $1"
    shift
done

partitions=
for disk in $devices; do
    fdisk $disk << EOF
n
p
1


t
fd
w
EOF
    partitions="$partitions $(fdisk -l $disk | grep '^/dev' | cut -d' ' -f1)"
done

ndevices=$(echo $partitions | wc -w)

sleep 10
mdadm --create $raid_device --level 0 --raid-devices $ndevices $partitions
sleep 10
