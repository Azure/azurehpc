#!/bin/bash
device=$1
filesystem=${2-xfs}
mount=${3-/share}

if [[ $(id -u) -ne 0 ]] ; then
    echo "Must be run as root"
    exit 1
fi

echo "Creating a $filesystem filesystem on device $device mounted on $mount"

case $filesystem in
    xfs)
        mkfs -t $filesystem $device || exit 1
        xfsuuid="UUID=`blkid |grep $device |cut -d " " -f 2 |cut -c 7-42`"
        echo "$xfsuuid $mount $filesystem rw,noatime,attr2,inode64,nobarrier,nofail 0 2" >> /etc/fstab
    ;;

    ext4)
        mkfs.ext4 -F -m 0 -i 2048 -I 512 -J size=400 -Odir_index,filetype $device || exit 1
        sleep 5
        tune2fs -o user_xattr $device
        ext4uuid="UUID=`blkid |grep $device |cut -d " " -f 2 |cut -c 7-42`"
        echo "$ext4uuid $mount $filesystem noatime,nodiratime,nobarrier,nofail 0 2" >> /etc/fstab
    ;;

    *)
        echo "filesystem not supported"
        exit 1
    ;;
esac

sleep 10
mkdir -p $mount
mount $mount
chmod 777 $mount
