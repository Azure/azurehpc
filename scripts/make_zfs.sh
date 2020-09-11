#!/bin/bash

name=$1
mount_point=$2
shift 2
# storage devices are the remaining args

# install ZFS
centos_version=$(sed 's/CentOS Linux release \([[:digit:]]\.[[:digit:]]\).*/\1/' < /etc/redhat-release)
zfs_release_rpm="http://download.zfsonlinux.org/epel/zfs-release.el${centos_version/./_}.noarch.rpm"
yum install -y $zfs_release_rpm
yum install -y zfs
modprobe zfs

zpool create $name "$@"
zfs set mountpoint=$mount_point $name
