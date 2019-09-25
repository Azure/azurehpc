#!/bin/bash
#
disk_type=$1
node_type=$2
pools=$3
MGMT_HOSTNAME=$4
#
if [ $disk_type == "local_ssd" ]; then
BEEGFS_DISK=/mnt/resource/beegfs
else
BEEGFS_DISK=/mnt/beegfs
fi

BEEGFS_METADATA=${BEEGFS_DISK}/meta
#
yum install -y beegfs-meta
sed -i 's|^storeMetaDirectory.*|storeMetaDirectory = '$BEEGFS_METADATA'|g' /etc/beegfs/beegfs-meta.conf
sed -i 's/^sysMgmtdHost.*/sysMgmtdHost = '$MGMT_HOSTNAME'/g' /etc/beegfs/beegfs-meta.conf
#
sed -i 's/^connMaxInternodeNum.*/connMaxInternodeNum = 800/g' /etc/beegfs/beegfs-meta.conf
sed -i 's/^tuneNumWorkers.*/tuneNumWorkers = 128/g' /etc/beegfs/beegfs-meta.conf
#
setup_data_disks()
{
    mountPoint="$1"
    filesystem="$2"
    devices="$3"
    raidDevice="$4"
    createdPartitions=""
    numdevices=`echo $devices | wc -w`
    if [ $numdevices -gt 1 ]
    then
    # Loop through and partition disks until not found
       for disk in $devices; do
           fdisk -l /dev/$disk || break
           fdisk /dev/$disk << EOF
n
p
1


t
fd
w
EOF
           if [ $raidDevice == "md30" ]
           then
              createdPartitions="$createdPartitions /dev/${disk}p1"
           else
              createdPartitions="$createdPartitions /dev/${disk}1"
           fi
       done
    else
        disk=$(echo $devices | tr -d [:space:])
        echo "Warning: Only a single device to partition, $disk"
        fdisk -l /dev/$disk || break
        fdisk /dev/$disk << EOF
n
p
1


w
EOF
        if [ $raidDevice == "md30" ]
        then
           createdPartitions="$createdPartitions /dev/${disk}p1"
        else
           createdPartitions="$createdPartitions /dev/${disk}1"
        fi
    fi

    sleep 10

    # Create RAID-0 volume
    if [ -n "$createdPartitions" ]; then
        devices=`echo $createdPartitions | wc -w`
        if [ $numdevices -gt 1 ]
        then
           mdadm --create /dev/$raidDevice --level 0 --raid-devices $devices $createdPartitions
           sleep 10

           mdadm /dev/$raidDevice
        else
           echo "Warning: mdadm is not called, we have one partition named, ${disk}1 for mountpoint, $mountPoint"
           if [ $raidDevice == "md30" ]
           then
              raidDevice=${disk}p1
           else
              raidDevice=${disk}1
           fi
        fi
        if is_restart; then
           systemctl disable beegfs-meta.service
           systemctl disable beegfs-storage.service
           sed -i '$ d' /etc/fstab
        fi
        if [ "$filesystem" == "xfs" ]; then
            mkfs -t $filesystem /dev/$raidDevice
            export xfsuuid="UUID=`blkid |grep dev/$raidDevice |cut -d " " -f 2 |cut -c 7-42`"
            echo "$xfsuuid $mountPoint $filesystem rw,noatime,attr2,inode64,nobarrier,nofail 0 2" >> /etc/fstab
        else
            mkfs.ext4 -i 2048 -I 512 -J size=400 -Odir_index,filetype /dev/$raidDevice
            sleep 5
            tune2fs -o user_xattr /dev/$raidDevice
            export ext4uuid="UUID=`blkid |grep dev/$raidDevice |cut -d " " -f 2 |cut -c 7-42`"
            echo "$ext4uuid $mountPoint $filesystem noatime,nodiratime,nobarrier,nofail 0 2" >> /etc/fstab
        fi

        sleep 10
        mount -a
    fi
}
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
   metadataDevices="`fdisk -l | grep '^Disk /dev/' | grep -v '/dev/md' | grep -v $hddDiskSize | grep -v $rootDevice | grep -v $tmpDevice | grep $metadataDiskSize | awk '{print $2}' | awk -F: '{print $1}' | sort | head -$nbMetadaDisks | tr '\n' ' ' | sed 's|/dev/||g'`"
else
   metadataDevices="`fdisk -l | grep '^Disk /dev/' | grep -v '/dev/md' | grep -v $hddDiskSize | grep -v $rootDevice | grep -v $tmpDevice | grep $metadataDiskSize | awk '{print $2}' | awk -F: '{print $1}' | sort | tr '\n' ' ' | sed 's|/dev/||g'`"
fi
#
mkdir -p $BEEGFS_METADATA
if [ $disk_type == "data_disk" ]; then
   setup_data_disks $BEEGFS_METADATA "ext4" "$metadataDevices" "md20"
fi
#
mount -a
#
systemctl daemon-reload
systemctl enable beegfs-meta.service
systemctl start beegfs-meta.service
#
