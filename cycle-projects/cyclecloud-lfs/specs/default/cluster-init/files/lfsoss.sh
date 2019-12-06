#!/bin/bash

# arg: $1 = lfsmaster
# arg: $2 = device (e.g. L=/dev/sdb Lv2=/dev/nvme0n1)
master=$1
device=$2
index=$(($PSSH_NODENUM + 1))

mkfs.lustre \
    --fsname=LustreFS \
    --backfstype=ldiskfs \
    --reformat \
    --ost \
    --mgsnode=$master \
    --index=$index \
    --mountfsoptions="errors=remount-ro" \
    $device

mkdir /mnt/oss
echo "$device /mnt/oss lustre noatime,nodiratime,nobarrier 0 2" >> /etc/fstab
mount -a
