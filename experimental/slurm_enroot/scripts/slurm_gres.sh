#!/bin/bash
# Configure slurmd to use a gres/gpu node

echo "AutoDetect=nvml" > /etc/slurm/gres.conf

num_gpus=$(nvidia-smi -L | wc -l)

sed -i "s/$/ gres=gpu:$num_gpus/" /apps/slurm/nodeconf/$HOSTNAME
#grep GresTypes /apps/slurm/slurm.conf || echo "GresTypes=gpu" >> /apps/slurm/slurm.conf

exit 0
