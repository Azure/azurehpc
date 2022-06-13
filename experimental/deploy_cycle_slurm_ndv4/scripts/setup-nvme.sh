#!/bin/bash

NVME_DISKS_NAME=`ls /dev/nvme*n1`
NVME_DISKS=`ls -latr /dev/nvme*n1 | wc -l`

echo "Number of NVMe Disks: $NVME_DISKS"

if [ "$NVME_DISKS" == "0" ]
then
    exit 0
else
    mkdir /mnt/resource_nvme
    mdadm --create /dev/md128 --level 0 --raid-devices $NVME_DISKS $NVME_DISKS_NAME
    mkfs.xfs /dev/md128
#   echo "/dev/md128 /mnt/resource_nvme xfs" >> /etc/fstab
    mount /dev/md128 /mnt/resource_nvme
#    mount /mnt/resource_nvme
    chmod 777 /mnt/resource_nvme
fi
