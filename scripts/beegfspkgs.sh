#!/bin/bash
#
set -e
export LANG=en_US.UTF-8 # to avoid the "Failed to set locale, defaulting to C" yum error message
BEEGFS_VER=${1-7_1}

RELEASE=$(cat /etc/redhat-release | cut -d' ' -f4)
KERNEL=$(uname -r)
echo "Kernel version is $KERNEL"
#
systemctl stop firewalld
systemctl disable firewalld
#
yum -y install epel-release
repo=updates
set +e
status=$(yum repoinfo updates-openlogic | grep enabled)
if [ "$status" != "" ]; then
    repo=updates-openlogic
fi
echo "repo to install kernel headers is $repo"
set -e
yum -y install --disablerepo=* --enablerepo=$repo --releasever=$RELEASE kernel-devel-${KERNEL} kernel-headers-${KERNEL} kernel-tools-libs-devel-${KERNEL}

yum -y install gcc gcc-c++
yum -y install zlib zlib-devel bzip2 bzip2-devel bzip2-libs openssl openssl-devel openssl-libs nfs-utils rpcbind mdadm wget python-pip automake autoconf
#
wget -q -O /etc/yum.repos.d/beegfs-rhel7.repo https://www.beegfs.io/release/beegfs_${BEEGFS_VER}/dists/beegfs-rhel7.repo
sed -i "s/beegfs_7_1/beegfs_${BEEGFS_VER}/g" /etc/yum.repos.d/beegfs-rhel7.repo

rpm --import https://www.beegfs.io/release/latest-stable/gpg/RPM-GPG-KEY-beegfs
#
echo "net.ipv4.neigh.default.gc_thresh1=1100" | tee -a /etc/sysctl.conf
echo "net.ipv4.neigh.default.gc_thresh2=2200" | tee -a /etc/sysctl.conf
echo "net.ipv4.neigh.default.gc_thresh3=4400" | tee -a /etc/sysctl.conf
sysctl -p
