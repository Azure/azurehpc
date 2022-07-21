#!/bin/bash

function is_slurm_controller() {
   systemctl list-units --full -all | grep -q slurmctld
}

if ! is_slurm_controller; then
   cd /usr/local/cuda/samples/1_Utilities/bandwidthTest
   make
fi
