#!/bin/bash

function set_detached_mode() {
   TARGET_MODE=$1
   sudo sed -i "s/DETACHED_MODE.*/DETACHED_MODE=${TARGET_MODE}/g" /etc/default/nhc
}

function exclusive_node() {
if [ -d "/sys/fs/cgroup/memory/slurm" ]; then
   # Ubuntu 20.04
   BASE_DIR="/sys/fs/cgroup/memory/slurm/uid_*"
else
   # Ubuntu 22.04
   BASE_DIR="/sys/fs/cgroup/system.slice/${HOSTNAME}_slurmstepd.scope"
fi

NUM_JOBS=$(ls -ld ${BASE_DIR}/job* 2> /dev/null | wc -l)

if [[ $NUM_JOBS -gt 0 ]]; then
   return 1
fi
}

prolog_epilog=$1
exclusive_node
exclusive_node_rc=$?

NHC_RC=0
if [ $exclusive_node_rc -eq 0 ]; then
   set_detached_mode 0
   echo "[$prolog_eplilog] execute nhc" >> /var/log/nhc.log
   sudo /usr/sbin/nhc
   NHC_RC=$?
   set_detached_mode 1
fi
