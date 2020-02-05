#!/bin/bash
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum history new

RELEASE=$(cat /etc/redhat-release | cut -d' ' -f4)
echo $RELEASE
yum install -y --disablerepo=openlogic --releasever=$RELEASE dkms

CUDA_REPO_PKG=cuda-repo-rhel7-10.1.243-1.x86_64.rpm

wget -q http://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/${CUDA_REPO_PKG}
rpm -ivh ${CUDA_REPO_PKG}
rm -f ${CUDA_REPO_PKG}
yum history new
yum install -y cuda-drivers
