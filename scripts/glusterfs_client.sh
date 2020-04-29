#!/bin/bash

NODE=$1
MOUNT_PT=$2

mkdir -p $MOUNT_PT

echo "${NODE}:/gv0 $MOUNT_PT glusterfs defaults,_netdev 0 0" >> /etc/fstab
mount -a

chmod 777 $MOUNT_PT
