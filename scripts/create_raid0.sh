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

echo "devices=$devices"

# print partition information
parted -s --list 2>/dev/null

# creating the partitions
for disk in $devices; do
    echo "partitioning $disk"
    parted -s $disk "mklabel gpt"
    parted -s $disk -a optimal "mkpart primary 1 -1"
    parted -s $disk print
    parted -s $disk "set 1 raid on"
done

# make sure all the partitions are ready
sleep 10
# get the partition names
partitions=
for disk in $devices; do
    partitions="$partitions $(lsblk -no kname -p $disk | tail -n1)"
done
echo "partitions=$partitions"

ndevices=$(echo $partitions | wc -w)

echo "creating raid device"
mdadm --create $raid_device --level 0 --raid-devices $ndevices $partitions || exit 1
sleep 10

mdadm --verbose --detail --scan > /etc/mdadm.conf
