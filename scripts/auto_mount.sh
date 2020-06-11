#!/bin/bash
yum install -y nfs-utils

mountpath = $1
mountpoint = $2

mkdir -p $mountpoint

echo "$mountpath $mountpoint nfs bg,rw,hard,noatime,nolock,rsize=65536,wsize=65536,vers=3,tcp,_netdev 0 0" >>/etc/fstab

mount -a

chmod 777 $mountpoint
