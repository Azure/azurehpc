#!/bin/bash

source $CYCLECLOUD_SPEC_PATH/files/common_functions.sh

# Install extra hooks for PMIx on compute nodes
if ! is_slurm_controller; then
   cp -fv /usr/share/enroot/hooks.d/50-slurm-pmi.sh /usr/share/enroot/hooks.d/50-slurm-pytorch.sh /etc/enroot/hooks.d
fi
