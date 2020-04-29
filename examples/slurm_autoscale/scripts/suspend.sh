#!/bin/bash

NODES=$1

echo "$(date) : [suspend.sh] : running suspend with options $@" >> /var/log/slurm/autoscale.log

az login --identity

source /apps/slurm/azurehpc/install.sh

cd /apps/slurm/azscale
azhpc slurm_suspend "$NODES" >> /var/log/slurm/autoscale.log 2>&1

echo "$(date) : [suspend.sh] : exiting" >> /var/log/slurm/autoscale.log