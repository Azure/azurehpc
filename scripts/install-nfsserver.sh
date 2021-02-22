#!/bin/bash
NFS_MOUNT_POINT=${1-/share}
if [[ $(id -u) -ne 0 ]] ; then
    echo "Must be run as root"
    exit 1
fi

set -e
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$script_dir/azhpc-library.sh" 
read_os

yum -y install epel-release

case "$os_maj_ver" in
    7)
        yum_list="nfs-utils nfs-utils-lib"
    ;;
    8)
        yum_list="nfs-utils"
    ;;
esac
yum -y install $yum_list

# Shares
NFS_APPS=$NFS_MOUNT_POINT/apps
NFS_DATA=$NFS_MOUNT_POINT/data
NFS_HOME=$NFS_MOUNT_POINT/home
NFS_SCRATCH=/mnt/resource/scratch

systemctl enable rpcbind
systemctl enable nfs-server
if is_centos7; then
    systemctl enable nfs-lock
    systemctl enable nfs-idmap
    systemctl enable nfs
fi

systemctl start rpcbind
systemctl start nfs-server
if is_centos7; then
    systemctl start nfs-lock
    systemctl start nfs-idmap
    systemctl start nfs
fi

######################################
# Create shares and exports
######################################
mkdir -p $NFS_APPS
mkdir -p $NFS_DATA
mkdir -p $NFS_HOME
mkdir -p $NFS_SCRATCH
chmod 777 $NFS_APPS
chmod 777 $NFS_DATA
chmod 777 $NFS_HOME
chmod 777 $NFS_SCRATCH

ln -s $NFS_SCRATCH /scratch
ln -s $NFS_APPS /apps
ln -s $NFS_DATA /data

echo "$NFS_APPS    *(rw,sync,no_root_squash)" >> /etc/exports
echo "$NFS_DATA    *(rw,sync,no_root_squash)" >> /etc/exports
echo "$NFS_HOME    *(rw,sync,no_root_squash)" >> /etc/exports
echo "$NFS_SCRATCH    *(rw,sync,no_root_squash)" >> /etc/exports

exportfs
exportfs -a
exportfs

########################################
# Tune NFS
########################################

cores=$(grep processor /proc/cpuinfo | wc -l)
nfs_proc=$(($cores * 4))
sed -i -e "s/#\[nfsd\]/\[nfsd\]/g" /etc/nfs.conf
replace="s/# threads=8/threads=$nfs_proc/g"
sed -i -e "$replace" /etc/nfs.conf

systemctl restart nfs-server

# Dump the NFSD stats
cat /proc/net/rpc/nfsd

df -h
