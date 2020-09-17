#!/bin/bash

# arg: $1 = device (e.g. L=/dev/sdb Lv2=/dev/nvme0n1)
device=$1

# this will only install MDS on first node in a scaleset
if [ "$PSSH_NODENUM" = "0" ]; then

    mkfs.lustre --fsname=LustreFS --mgs --mdt --mountfsoptions="user_xattr,errors=remount-ro" --backfstype=ldiskfs --reformat $device --index 0

    mkdir /mnt/mgsmds
    echo "$device /mnt/mgsmds lustre noatime,nodiratime,nobarrier 0 2" >> /etc/fstab
    mount -a

fi