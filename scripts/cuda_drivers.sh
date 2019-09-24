#!/bin/bash

rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

yum install -y dkms

CUDA_REPO_PKG=cuda-repo-rhel7-10.1.243-1.x86_64.rpm

wget http://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/${CUDA_REPO_PKG} -O /mnt/resource/${CUDA_REPO_PKG}

rpm -ivh /mnt/resource/${CUDA_REPO_PKG}

rm -f /mnt/resource/${CUDA_REPO_PKG}

yum install -y cuda-drivers

# dump GPU card status
nvidia-smi

