#!/bin/bash

set -x

#TODO: Install nvidia drivers if needed.

# Install NVIDIA container support
DIST=$(. /etc/os-release; echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/libnvidia-container/$DIST/libnvidia-container.repo > /etc/yum.repos.d/libnvidia-container.repo

yum -y makecache
yum -y install libnvidia-container-tools
