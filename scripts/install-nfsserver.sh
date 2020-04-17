#!/bin/bash
NFS_MOUNT_POINT=${1-/share}
if [[ $(id -u) -ne 0 ]] ; then
    echo "Must be run as root"
    exit 1
fi

yum -y install epel-release
yum -y install nfs-utils nfs-utils-lib

# Shares
NFS_APPS=$NFS_MOUNT_POINT/apps
NFS_DATA=$NFS_MOUNT_POINT/data
NFS_HOME=$NFS_MOUNT_POINT/home
NFS_SCRATCH=/mnt/resource/scratch

systemctl enable rpcbind
systemctl enable nfs-server
systemctl enable nfs-lock
systemctl enable nfs-idmap
systemctl enable nfs

systemctl start rpcbind
systemctl start nfs-server
systemctl start nfs-lock
systemctl start nfs-idmap
systemctl start nfs

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
replace="s/#RPCNFSDCOUNT=16/RPCNFSDCOUNT=$nfs_proc/g"
sed -i -e "$replace" /etc/sysconfig/nfs
grep RPCNFSDCOUNT /etc/sysconfig/nfs

systemctl restart nfs-server

df -h
