#!/bin/bash

RESOURCEGROUP=paul-slurm-test
NODES=""

echo "$(date) : [suspend.sh] : running suspend with options $@" >> /var/log/slurm/autoscale.log

az login --identity

source /apps/slurm/azurehpc/install.sh

cd /apps/slurm/azscale
export PYTHONPATH=$PYTHONPATH:$AZHPC_PYTHONPATH
$azhpc_pypath $azhpc_dir/pyazhpc/azhpc.py slurm_suspend "$NODES" >> /var/log/slurm/autoscale.log 2>&1

echo "$(date) : [suspend.sh] : exiting" >> /var/log/slurm/autoscale.log