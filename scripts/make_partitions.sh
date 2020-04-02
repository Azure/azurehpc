#!/bin/bash
# arg: $1 = devices to use (can use globbing)
devices=$1

for disk in $devices; do
    # https://docs.microsoft.com/en-us/azure/virtual-machines/linux/attach-disk-portal
    parted $disk --script mklabel gpt mkpart xfspart xfs 0% 100%
    partprobe ${disk}1
done
