#!/bin/bash

#expect to see 8 GPU's

HOSTNAME=`hostname`
OUT_DIR=/shared/home/cycleadmin/healthchecks/misc_gpu/out

num_gpus=`nvidia-smi --list-gpus | wc -l`

echo "num_gpus= $num_gpus" > ${OUT_DIR}/${HOSTNAME}_num_gpus.out
