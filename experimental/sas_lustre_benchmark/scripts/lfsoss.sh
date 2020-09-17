#!/bin/bash

# arg: $1 = lfsmaster
# arg: $* = devices (e.g. L=/dev/sdb Lv2=/dev/nvme0n1)
master=$1
shift
ndevices=$#
index=$(( $ndevices * $PSSH_NODENUM ))

for i in $(seq 1 $ndevices); do

    device=$1
    shift

    mkfs.lustre \
        --fsname=LustreFS \
        --backfstype=ldiskfs \
        --reformat \
        --ost \
        --mgsnode=$master \
        --index=$(( $index + $i ))  \
        --mountfsoptions="errors=remount-ro" \
        $device

    mkdir /mnt/oss$(( $index + $i ))
    echo "$device /mnt/oss$(( $index + $i )) lustre defaults,_netdev 0 0" >> /etc/fstab

    chmod 777 /mnt/oss*
    chown nobody:nobody /mnt/oss*

done

mount -a
