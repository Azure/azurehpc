#!/bin/bash
device=$1
filesystem=${2-xfs}
mount=${3-/share}

# Check if mount exist
if [ -d "$mount" ];then
    echo "Script was already run. Exiting"
    exit 0
fi

if [[ $(id -u) -ne 0 ]] ; then
    echo "Must be run as root"
    exit 1
fi

# Check to see which OS this is running on.
os_release=$(cat /etc/os-release | grep "^ID\=" | cut -d'=' -f 2 | sed -e 's/^"//' -e 's/"$//')
os_maj_ver=$(cat /etc/os-release | grep "^VERSION_ID\=" | cut -d'=' -f 2 | sed -e 's/^"//' -e 's/"$//')

echo "Creating a $filesystem filesystem on device $device mounted on $mount"

case $filesystem in
    xfs)
        mkfs -t $filesystem $device || exit 1
        xfsuuid="UUID=`blkid |grep $device |cut -d " " -f 2 |cut -c 7-42`"
        if [ "$os_release" == "centos" ];then
            echo "$xfsuuid $mount $filesystem rw,noatime,attr2,inode64,nobarrier,nofail 0 2" >> /etc/fstab
        elif [ "$os_release" == "ubuntu" ];then
            echo "$xfsuuid $mount $filesystem rw,noatime,attr2,inode64,nofail 0 2" >> /etc/fstab
        fi
    ;;

    ext4)
        mkfs.ext4 -F -m 0 -i 2048 -I 512 -J size=400 -Odir_index,filetype $device || exit 1
        sleep 5
        tune2fs -o user_xattr $device
        ext4uuid="UUID=`blkid |grep $device |cut -d " " -f 2 |cut -c 7-42`"
        if [ "$os_release" == "centos" ];then
            echo "$ext4uuid $mount $filesystem noatime,nodiratime,nobarrier,nofail 0 2" >> /etc/fstab
        elif [ "$os_release" == "ubuntu" ];then
            echo "$ext4uuid $mount $filesystem noatime,nodiratime,nofail 0 2" >> /etc/fstab
        fi 
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
