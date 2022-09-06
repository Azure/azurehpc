#!/bin/bash

TCP_MAX_SLOT_TABLE_ENTRIES=128
SYSCTL_CONF=/etc/sysctl.conf
ANF_MOUNT_POINTS="/apps /shared"

echo "sunrpc.tcp_max_slot_table_entries=$TCP_MAX_SLOT_TABLE_ENTRIES" | sudo tee -a $SYSCTL_CONF > /dev/null
sysctl -p

for mount_point in $ANF_MOUNT_POINTS
do
   umount $mount_point
   mount $mount_point
done
