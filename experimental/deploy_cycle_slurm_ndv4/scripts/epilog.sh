#!/bin/bash

RC1=1
RC2=0
PROLOGSLURMCTLD_LOG=/sched/logs/prologslurmctld.log

if [ -f $PROLOGSLURMCTLD_LOG ]; then
   grep -q "$SLURM_JOBID requeued" $PROLOGSLURMCTLD_LOG
   RC1=$?
   grep -q "$SLURM_JOBID started" $PROLOGSLURMCTLD_LOG
   RC2=$?
fi
echo "RC1=$RC1 RC2=$RC2" >> /tmp/epilog.log

if [[ $RC1 != 0 || $RC2 != 1 ]]; then
   echo "run run_nhc.sh" >> /tmp/epilog.log
   /sched/scripts/run_nhc.sh
fi

exit 0
