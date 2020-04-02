#!/bin/bash
device=$1
filesystem=${2-xfs}
mount=${3-/data}

echo "Creating a $filesystem filesystem on device $device mounted on $mount"
if [[ $(id -u) -ne 0 ]] ; then
    echo "Must be run as root"
    exit 1
fi

if [ "$filesystem" == "xfs" ]; then
    mkfs -t $filesystem /dev/$device
    xfsuuid="UUID=`blkid |grep dev/$device |cut -d " " -f 2 |cut -c 7-42`"
    echo "$xfsuuid $mount $filesystem rw,noatime,attr2,inode64,nobarrier,nofail 0 2" >> /etc/fstab
else
    mkfs.ext4 -i 2048 -I 512 -J size=400 -Odir_index,filetype /dev/$device
    sleep 5
    tune2fs -o user_xattr /dev/$device
    ext4uuid="UUID=`blkid |grep dev/$device |cut -d " " -f 2 |cut -c 7-42`"
    echo "$ext4uuid $mount $filesystem noatime,nodiratime,nobarrier,nofail 0 2" >> /etc/fstab
fi

sleep 10
mkdir $mount
mount $mount
