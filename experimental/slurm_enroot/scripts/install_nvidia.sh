#!/bin/bash

set -x

# Install nvidia drivers
yum-config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/cuda-rhel7.repo
yum clean all
yum -y install nvidia-driver-latest-dkms
#yum -y install cuda-drivers cuda


# Install NVIDIA container support
DIST=$(. /etc/os-release; echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/libnvidia-container/$DIST/libnvidia-container.repo > /etc/yum.repos.d/libnvidia-container.repo

yum -y makecache
yum -y install libnvidia-container-tools

# Example container from NGC:
# enroot import -o /mnt/resource/pytorch.sqsh 'docker://nvcr.io#nvidia/pytorch:21.06-py3'
# enroot import pytorch
# enroot start pytorch