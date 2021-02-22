#!/bin/bash

# arg: $1 = lfsserver
# arg: $2 = mount point (default: /lustre)
master=$1
lfs_mount=${2:-/lustre}

BUILD_PATH=/tmp
LUSTRE_RELEASE=f710782
LUSTRE_PATCH_NUMBER=41152
MLNX_OFED_DOWNLOAD_URL=https://azhpcstor.blob.core.windows.net/azhpc-images-store/MLNX_OFED_LINUX-5.2-1.0.4.0-rhel7.8-x86_64.tgz

MLNX_TARBALL=$(basename ${MLNX_OFED_DOWNLOAD_URL})
MOFED_FOLDER=$(basename ${MLNX_OFED_DOWNLOAD_URL} .tgz)

cd $BUILD_PATH
wget -O  $MLNX_TARBALL $MLNX_OFED_DOWNLOAD_URL
tar xvf $MLNX_TARBALL

mkdir $LUSTRE_RELEASE
cd $LUSTRE_RELEASE
wget -O ${LUSTRE_RELEASE}.tar.gz https://review.whamcloud.com/changes/${LUSTRE_PATCH_NUMBER}/revisions/f710782156ec21a8a69d7f12a9e7de1bde02c22b/archive?format=tgz
tar xvf ${LUSTRE_RELEASE}.tar.gz

chmod 777 ./autogen.sh
./autogen.sh

yum install -y libselinux-devel

./configure
make
make rpms


yum install ${BUILD_PATH}/${MOFED_FOLDER}/RPMS/kmod-mlnx-ofa_kernel-5.2-OFED.5.2.1.0.4.1.rhel7u8.x86_64.rpm

rpm -ivh ${BUILD_PATH}/${LUSTRE_RELEASE}/kmod-lustre-client-2.12.6-1.el7.x86_64.rpm
rpm -ivh ${BUILD_PATH}/${LUSTRE_RELEASE}/lustre-client-2.12.6-1.el7.x86_64.rpm

weak-modules --add-kernel $(uname -r)

mkdir $lfs_mount
echo "${master}@tcp0:/LustreFS $lfs_mount lustre flock,defaults,_netdev 0 0" >> /etc/fstab
mount -a
chmod 777 $lfs_mount
