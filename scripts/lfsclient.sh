#!/bin/bash

# arg: $1 = lfsserver
# arg: $2 = mount point (default: /lustre)
master=$1
lfs_mount=${2:-/lustre}

yum install -y kmod-lustre-client lustre-client
weak-modules --add-kernel $(uname -r)

mkdir $lfs_mount
echo "${master}@tcp0:/LustreFS $lfs_mount lustre defaults,_netdev 0 0" >> /etc/fstab
mount -a
chmod 777 $lfs_mount
