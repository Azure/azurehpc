#!/bin/bash
# arg: 
#   $1 = devices to use (can use globbing)
#   $2 = filesystem to use (xfs or ext4)

devices=$1
filesystem=${2-xfs}

case $filesystem in
    xfs)
        parted_options="xfspart xfs"
    ;;

    ext4)
        parted_options="ext4part ext4"
    ;;

    *)
        echo "not supported filesystem"
        exit 1
    ;;
esac

for disk in $devices; do
    # https://docs.microsoft.com/en-us/azure/virtual-machines/linux/attach-disk-portal
    parted $disk --script mklabel gpt mkpart $parted_options 0% 100%
    partprobe ${disk}1
done
