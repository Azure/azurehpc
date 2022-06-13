#!/bin/bash

SCRIPTS_DIR=/root

if [ -b /dev/md127 ]; then
   DEV=/dev/md127
elif [ -b /dev/md128 ]; then
   DEV=/dev/md128
else
   ${SCRIPTS_DIR}/setup_nvme_heal.sh
fi

if [ -n "$DEV" ]; then
   mount $DEV /mnt/resource_nvme
fi

${SCRIPTS_DIR}/max_gpu_app_clocks.sh
nvidia-smi -pm 1
