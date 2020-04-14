#!/bin/bash
# Dependencies on make_filesystems.sh and make_partitions.sh
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ $(id -u) -ne 0 ]] ; then
    echo "Must be run as root"
    exit 1
fi

# Disable requiretty to allow run sudo within scripts
sed -i -e 's/Defaults    requiretty.*/ #Defaults    requiretty/g' /etc/sudoers

yum -y install epel-release
yum -y install nfs-utils nfs-utils-lib

# Shares
NFS_MOUNT_POINT=/share
NFS_APPS=$NFS_MOUNT_POINT/apps
NFS_DATA=$NFS_MOUNT_POINT/data
NFS_HOME=$NFS_MOUNT_POINT/home
NFS_SCRATCH=/mnt/resource/scratch

setup_disks()
{
    # Dump the current disk config for debugging
    fdisk -l

    # Dump the scsi config
    lsscsi

    # Get the root/OS disk so we know which device it uses and can ignore it later
    rootDevice=`mount | grep "on / type" | awk '{print $1}' | sed 's/[0-9]//g'`

    # Get the TMP disk so we know which device and can ignore it later
    tmpDevice=`mount | grep "on /mnt/resource type" | awk '{print $1}' | sed 's/[0-9]//g'`

    # Get the data disk sizes from fdisk, we ignore the disks above
    dataDiskSize=`fdisk -l | grep '^Disk /dev/' | grep -v $rootDevice | grep -v $tmpDevice | awk '{print $3}' | sort -n -r | tail -1`

    # Compute number of disks
    nbDisks=`fdisk -l | grep '^Disk /dev/' | grep -v $rootDevice | grep -v $tmpDevice | wc -l`
    echo "nbDisks=$nbDisks"

    dataDevices="`fdisk -l | grep '^Disk /dev/' | grep $dataDiskSize | awk '{print $2}' | awk -F: '{print $1}' | sort | head -$nbDisks | tr '\n' ' ' `"

    mkdir -p $NFS_MOUNT_POINT

    if [ "$nbDisks" -eq "1" ]; then
        #setup_single_disk $NFS_MOUNT_POINT "ext4" "$dataDevices"
        #$DIR/make_partitions.sh $dataDevices
        $DIR/make_filesystem.sh $dataDevices "xfs" $NFS_MOUNT_POINT
    elif [ "$nbDisks" -gt "1" ]; then
        raid_device="md10"
        $DIR/create_raid0.sh $raid_device "$dataDevices"
        $DIR/make_filesystem.sh $raid_device "xfs" $NFS_MOUNT_POINT
    fi

    mkdir -p $NFS_APPS
    mkdir -p $NFS_DATA
    mkdir -p $NFS_HOME
    mkdir -p $NFS_SCRATCH
    chmod 777 $NFS_APPS
    chmod 777 $NFS_DATA
    chmod 777 $NFS_HOME
    chmod 777 $NFS_SCRATCH

    ln -s $NFS_SCRATCH /scratch

    echo "$NFS_APPS    *(rw,sync,no_root_squash)" >> /etc/exports
    echo "$NFS_DATA    *(rw,sync,no_root_squash)" >> /etc/exports
    echo "$NFS_HOME    *(rw,sync,no_root_squash)" >> /etc/exports
    echo "$NFS_SCRATCH    *(rw,sync,no_root_squash)" >> /etc/exports

    exportfs
    exportfs -a
    exportfs
}

tune_nfs()
{
    cores=$(grep processor /proc/cpuinfo | wc -l)
    nfs_proc=$(($cores * 4))
    replace="s/#RPCNFSDCOUNT=16/RPCNFSDCOUNT=$nfs_proc/g"
    sed -i -e "$replace" /etc/sysconfig/nfs

    grep RPCNFSDCOUNT /etc/sysconfig/nfs
}

systemctl enable rpcbind
systemctl enable nfs-server
systemctl enable nfs-lock
systemctl enable nfs-idmap
systemctl enable nfs

systemctl start rpcbind
systemctl start nfs-server
systemctl start nfs-lock
systemctl start nfs-idmap
systemctl start nfs

setup_disks
tune_nfs
systemctl restart nfs-server

ln -s /share/apps /apps
ln -s /share/data /data

df -h


