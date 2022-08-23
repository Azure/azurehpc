#!/bin/bash

ALLOCATED_NODES_THRESHOLD=64
PROLOGSLURMCTLD_LOG=/sched/logs/prologslurmctld.log

allocated_idle_str=$(sinfo -p hpc -h -o "%A")
IFS=$'/'
allocated_idle_array=( $allocated_idle_str )
IFS=$' \t\n'
allocated_nodes=${allocated_idle_array[0]}

TIMESTAMP=$(/bin/date '+%Y%m%d %H:%M:%S')
if [ $allocated_nodes -gt $ALLOCATED_NODES_THRESHOLD ]; then
   echo "${TIMESTAMP} Warning: (Allocated,threshold) = ($allocated_nodes,$ALLOCATED_NODES_THRESHOLD) nodes, job $SLURM_JOB_ID requeued" >> $PROLOGSLURMCTLD_LOG
   scontrol requeue $SLURM_JOB_ID
else
   grep -q "$SLURM_JOBID requeued" $PROLOGSLURMCTLD_LOG
   RC=$?
   if [ $RC == 0 ]; then
      echo "${TIMESTAMP} (Allocated,threshold) = ($allocated_nodes,$ALLOCATED_NODES_THRESHOLD) nodes, job $SLURM_JOB_ID started" >> $PROLOGSLURMCTLD_LOG
   fi
fi

exit 0
