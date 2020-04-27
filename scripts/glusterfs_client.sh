#!/bin/bash

NODE=$1
MOUNT_PT=$2

echo "mount -t glusterfs ${NODE}:/glusterfs_vol $MOUNT_PT flock" >> /etc/fstab
mount -a
chmod 777 $MOUNT_PT
