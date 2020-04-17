#!/bin/bash

# arg: $1 = nfsserver
nfs_server=$1
nfs_share=${2-/share}
if [ -z "$nfs_server" ]; then
    echo "The nfs_server is required"
    exit 1
fi

yum install -y nfs-utils

mkdir -p /scratch
mkdir -p /apps
mkdir -p /data
mkdir -p /share/home
mount $nfs_server:$nfs_share/apps /apps
mount $nfs_server:$nfs_share/data /data
mount $nfs_server:$nfs_share/home /share/home

chmod 777 /scratch

cat << EOF >> /etc/fstab
$nfs_server:$nfs_share/home           /share/home   nfs defaults 0 0
$nfs_server:/mnt/resource/scratch /scratch      nfs defaults 0 0
$nfs_server:$nfs_share/apps    /apps   nfs defaults 0 0
$nfs_server:$nfs_share/data    /data   nfs defaults 0 0
EOF

setsebool -P use_nfs_home_dirs 1

mount -a

df
