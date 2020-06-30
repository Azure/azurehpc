#!/bin/bash

# arg: $1 = lfsmaster
# arg: $2 = device (e.g. L=/dev/sdb Lv2=/dev/nvme0n1)
master=$1
device=$2

cp -r /share/home/hpcuser/.ssh /root/

index=$(($PSSH_NODENUM + 1))
myuser="hpcuser"

capture=$(ssh hpcuser@$master "sudo ip address show dev ib0")
masterib=$(echo $capture | awk -F 'inet' '{print $2}' | cut -d / -f 1 )

    lnetctl net add --net o2ib --if ib0 #double check
    mkfs.lustre \
    --fsname=LustreFS \
    --backfstype=ldiskfs \
    --reformat \
    --ost \
    --mgsnode="${masterib}@o2ib" \
    --index=$index \
    --mountfsoptions="errors=remount-ro" \
    $device


mkdir /mnt/oss
echo "$device /mnt/oss lustre noatime,nodiratime,nobarrier 0 2" >> /etc/fstab
mount -a
