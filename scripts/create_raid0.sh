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

    parted -s $disk "mklabel gpt"
    parted -s $disk -a optimal "mkpart primary 1 -1"
    parted -s $disk print
    parted -s $disk "set 1 raid on"

    partitions="$partitions ${disk}p1"
done

ndevices=$(echo $partitions | wc -w)

sleep 10
mdadm --create $raid_device --level 0 --raid-devices $ndevices $partitions
sleep 10

mdadm --verbose --detail --scan > /etc/mdadm.conf
