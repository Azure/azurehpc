#!/bin/bash
NFS_MOUNT_POINT=${1-/share}
if [[ $(id -u) -ne 0 ]] ; then
    echo "Must be run as root"
    exit 1
fi

# Check to see which OS this is running on. 
os_release=$(cat /etc/os-release | grep "^ID\=" | cut -d'=' -f 2 | sed -e 's/^"//' -e 's/"$//')
os_maj_ver=$(cat /etc/os-release | grep "^VERSION_ID\=" | cut -d'=' -f 2 | sed -e 's/^"//' -e 's/"$//')
echo "OS Release: $os_release"
echo "OS Major Version: $os_maj_ver"
if [ "$os_release" == "centos" ];then
    yum -y install epel-release
    yum -y install nfs-utils nfs-utils-lib
    # Start the services
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
elif [ "$os_release" == "ubuntu" ];then
    apt install nfs-kernel-server -y
    apt install lsscsi -y
    systemctl enable nfs-kernel-server
    systemctl start nfs-kernel-server
fi

# Shares
NFS_APPS=$NFS_MOUNT_POINT/apps
NFS_DATA=$NFS_MOUNT_POINT/data
NFS_HOME=$NFS_MOUNT_POINT/home
NFS_SCRATCH=/mnt/resource/scratch

######################################
# Create shares and exports
######################################
mkdir -p $NFS_APPS
mkdir -p $NFS_DATA
mkdir -p $NFS_HOME
mkdir -p $NFS_SCRATCH
chown nobody:nogroup $NFS_APPS
chown nobody:nogroup $NFS_DATA
chown nobody:nogroup $NFS_HOME
chown nobody:nogroup $NFS_SCRATCH
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

if [ "$os_release" == "centos" ];then
    systemctl restart nfs-server
elif [ "$os_release" == "ubuntu" ];then
    systemctl restart nfs-kernel-server
fi

df -h
