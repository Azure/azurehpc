#!/bin/bash

# arg: $1 = lfsserver
# arg: $2 = mount point (default: /lustre)
master=$1
lfs_mount=${2:-/lustre}

if [ "$lustre_version" = "2.10" ]; then
    yum install -y kmod-lustre-client
    weak-modules --add-kernel $(uname -r)
fi

mkdir $lfs_mount
echo "${master}@tcp0:/LustreFS $lfs_mount lustre defaults,_netdev 0 0" >> /etc/fstab
mount -a
chmod 777 $lfs_mount
