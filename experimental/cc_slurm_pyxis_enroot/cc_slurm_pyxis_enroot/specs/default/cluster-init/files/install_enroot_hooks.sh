#!/bin/bash

function is_slurm_controller() {
   systemctl list-units --full -all | grep -q slurmctld
}

# Install extra hooks for PMIx on compute nodes
if ! is_slurm_controller; then
   cp -fv /usr/share/enroot/hooks.d/50-slurm-pmi.sh /usr/share/enroot/hooks.d/50-slurm-pytorch.sh /etc/enroot/hooks.d
fi
