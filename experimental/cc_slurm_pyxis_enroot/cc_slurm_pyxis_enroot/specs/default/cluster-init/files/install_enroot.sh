#!/bin/bash

source $CYCLECLOUD_SPEC_PATH/files/common_functions.sh

ENROOT_VERSION_FULL=${1:-3.4.0-1}
ENROOT_VERSION=${ENROOT_VERSION_FULL%-*}

# Install enroot RPM packages on compute nodes
if ! is_slurm_controller; then

    cd /tmp

    # Install NVIDIA enroot
    curl -fSsL -O https://github.com/NVIDIA/enroot/releases/download/v${ENROOT_VERSION}/enroot_${ENROOT_VERSION_FULL}_amd64.deb
    curl -fSsL -O https://github.com/NVIDIA/enroot/releases/download/v${ENROOT_VERSION}/enroot+caps_${ENROOT_VERSION_FULL}_amd64.deb
    apt install -y ./enroot_${ENROOT_VERSION_FULL}_amd64.deb
    apt install -y ./enroot+caps_${ENROOT_VERSION_FULL}_amd64.deb

    # Install NVIDIA container support
    apt-get install -y libnvidia-container1 libnvidia-container-tools

    rm -f /tmp/enroot_${ENROOT_VERSION_FULL}_amd64.deb
    rm -f /tmp/enroot+caps_${ENROOT_VERSION_FULL}_amd64.deb

fi
