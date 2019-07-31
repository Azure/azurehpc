#!/bin/bash
#
disk_type=$1
node_type=$2
pools=$3
pools_restart=$4
#
BEEGFS_DISK=/mnt/beegfs
BEEGFS_HDD=/mnt/beegfs/hdd
#
yum install -y beegfs-storage
if [ $pools == "true" ]; then
   sed -i 's|^storeStorageDirectory.*|storeStorageDirectory = '$BEEGFS_HDD,$BEEGFS_STORAGE'|g' /etc/beegfs/beegfs-storage.conf
else
   sed -i 's|^storeStorageDirectory.*|storeStorageDirectory = '$BEEGFS_STORAGE'|g' /etc/beegfs/beegfs-storage.conf
fi
#
sed -i 's/^connMaxInternodeNum.*/connMaxInternodeNum = 800/g' /etc/beegfs/beegfs-storage.conf
sed -i 's/^tuneNumWorkers.*/tuneNumWorkers = 128/g' /etc/beegfs/beegfs-storage.conf
sed -i 's/^tuneFileReadAheadSize.*/tuneFileReadAheadSize = 32m/g' /etc/beegfs/beegfs-storage.conf
sed -i 's/^tuneFileReadAheadTriggerSize.*/tuneFileReadAheadTriggerSize = 2m/g' /etc/beegfs/beegfs-storage.conf
sed -i 's/^tuneFileReadSize.*/tuneFileReadSize = 256k/g' /etc/beegfs/beegfs-storage.conf
sed -i 's/^tuneFileWriteSize.*/tuneFileWriteSize = 256k/g' /etc/beegfs/beegfs-storage.conf
sed -i 's/^tuneWorkerBufSize.*/tuneWorkerBufSize = 16m/g' /etc/beegfs/beegfs-storage.conf
#
systemctl daemon-reload
systemctl enable beegfs-storage.service
#
fdisk -l
lsscsi
#
rootDevice=`mount | grep "on / type" | awk '{print $1}' | sed 's/[0-9]//g'`
tmpDevice=`mount | grep "on /mnt/resource type" | awk '{print $1}' | sed 's/[0-9]//g'`
#
hddDiskSize=default
if [ pools == "true" ]; then
   hddDiskSize=`fdisk -l | grep '^Disk /dev/sdc' | grep -v $rootDevice | grep -v $tmpDevice | awk '{print $3}'`
#   hddDevices="`fdisk -l | grep '^Disk /dev/' | grep -v $rootDevice | grep -v $tmpDevice | grep $hddDiskSize | awk '{print $2}' | awk -F: '{print $1}' | tr '\n' ' ' | sed 's|/dev/||g'`"
fi
#
metadataDiskSize=`fdisk -l | grep '^Disk /dev/' | grep -v '/dev/md' | grep -v $hddDiskSize | grep -v $rootDevice | grep -v $tmpDevice | awk '{print $3}' | sort -n -r | tail -1`
storageDiskSize=`fdisk -l | grep '^Disk /dev/' | grep -v '/dev/md' | grep -v $hddDiskSize | grep -v $rootDevice | grep -v $tmpDevice | awk '{print $3}' | sort -n | tail -1`
#
if [ "$metadataDiskSize" == "$storageDiskSize" ]; then
   nbDisks=`fdisk -l | grep '^Disk /dev/' | grep -v $hddDiskSize | grep -v $rootDevice | grep -v $tmpDevice | wc -l`
   let nbMetadaDisks=nbDisks
   let nbStorageDisks=nbDisks
   if [ $node_type == "both" ] && [ $disk_type == "data_disk" ]; then
      let nbMetadaDisks=nbDisks/3
      if [ $nbMetadaDisks -lt 2 ]; then
         let nbMetadaDisks=2
      fi
      let nbStorageDisks=nbDisks-nbMetadaDisks
   fi
   storageDevices="`fdisk -l | grep '^Disk /dev/' | grep -v '/dev/md' | grep -v $hddDiskSize | grep -v $rootDevice | grep -v $tmpDevice | grep $storageDiskSize | awk '{print $2}' | awk -F: '{print $1}' | sort | tail -$nbStorageDisks | tr '\n' ' ' | sed 's|/dev/||g'`"
else
   storageDevices="`fdisk -l | grep '^Disk /dev/' | grep -v '/dev/md' | grep -v $hddDiskSize | grep -v $rootDevice | grep -v $tmpDevice | grep $storageDiskSize | awk '{print $2}' | awk -F: '{print $1}' | sort | tr '\n' ' ' | sed 's|/dev/||g'`"
fi
#
if [ $pools == "true" ] && [ $pools_restart == "false" ]; then
   mkdir -p $BEEGFS_HDD
   setup_data_disks $BEEGFS_HDD "xfs" "$hddDevices" "md40"
fi
if [ $disk_type == "nvme" ]; then
   mkdir -p $BEEGFS_DISK
   setup_data_disks $BEEGFS_DISK "xfs" "$storageDevices" "md30"
   mkdir -p $BEEGFS_DISK/storage
elif [ $disk_type == "data_disk" ]; then
   mkdir -p $BEEGFS_DISK/storage
   setup_data_disks $BEEGFS_STORAGE "xfs" "$storageDevices" "md30"
else
   mkdir -p /mnt/resource/beegfs/storage
fi
mount -a 
