#!/bin/bash

# arg: $1 = nfsserver
nfs_server=$1
nfs_share=${2-/share}
if [ -z "$nfs_server" ]; then
    echo "The nfs_server is required"
    exit 1
fi

# Check to see which OS this is running on.
os_release=$(cat /etc/os-release | grep "^ID\=" | cut -d'=' -f 2 | sed -e 's/^"//' -e 's/"$//')
os_maj_ver=$(cat /etc/os-release | grep "^VERSION_ID\=" | cut -d'=' -f 2 | sed -e 's/^"//' -e 's/"$//')
echo "OS Release: $os_release"
echo "OS Major Version: $os_maj_ver"
if [ "$os_release" == "centos" ];then
    yum install -y nfs-utils
elif [ "$os_release" == "ubuntu" ];then
    apt install -y nfs-common
else
    echo "Unsupported Release: $os_release"
fi

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

if [ "$os_release" == "centos" ];then
    setsebool -P use_nfs_home_dirs 1
fi

mount -a

df
