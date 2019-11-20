#!/bin/bash

# arg: $1 = device (e.g. L=/dev/sdb Lv2=/dev/nvme0n1)
device=$1

# this will only install MDS on first node in a scaleset
if [ "$PSSH_NODENUM" = "0" ]; then

    mkfs.lustre --fsname=LustreFS --mgs --mdt --mountfsoptions="user_xattr,errors=remount-ro" --backfstype=ldiskfs --reformat $device --index 0

    mkdir /mnt/mgsmds
    echo "$device /mnt/mgsmds lustre noatime,nodiratime,nobarrier 0 2" >> /etc/fstab
    mount -a

    # set up hsm
    lctl set_param -P mdt.*-MDT0000.hsm_control=enabled
    lctl set_param -P mdt.*-MDT0000.hsm.default_archive_id=1
    lctl set_param mdt.*-MDT0000.hsm.max_requests=128

    # allow any user and group ids to write
    lctl set_param mdt.*-MDT0000.identity_upcall=NONE

fi