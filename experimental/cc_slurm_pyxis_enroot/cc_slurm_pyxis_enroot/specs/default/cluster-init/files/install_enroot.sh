#!/bin/bash

source $CYCLECLOUD_SPEC_PATH/files/common_functions.sh

ENROOT_VERSION='3.4.1-1'

# Install enroot RPM packages on compute nodes
if is_compute_node; then

    # Install NVIDIA enroot
    apt install -y $CYCLECLOUD_SPEC_PATH/files/enroot_${ENROOT_VERSION}_amd64.deb
    apt install -y $CYCLECLOUD_SPEC_PATH/files/enroot+caps_${ENROOT_VERSION}_amd64.deb

    # Install NVIDIA container support
    apt-get install -y libnvidia-container1=1.14.4-1 libnvidia-container-tools=1.14.4-1

fi
