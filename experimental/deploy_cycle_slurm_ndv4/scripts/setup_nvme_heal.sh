#!/bin/bash


NVME_DISKS_NAME=`ls /dev/nvme*n1`
NVME_DISKS=`ls -latr /dev/nvme*n1 | wc -l`

echo "Number of NVMe Disks: $NVME_DISKS"


while [  "$NVME_DISKS" != "8" ]
do
   sleep 1
   NVME_DISKS=`ls -latr /dev/nvme*n1 | wc -l`
done

mkdir -p /mnt/resource_nvme
/sbin/mdadm --create /dev/md128 --level 0 --raid-devices $NVME_DISKS $NVME_DISKS_NAME
/sbin/mkfs.xfs /dev/md128
mount /dev/md128 /mnt/resource_nvme
chmod 777 /mnt/resource_nvme
