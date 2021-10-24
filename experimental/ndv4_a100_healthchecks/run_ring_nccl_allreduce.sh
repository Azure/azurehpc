#!/bin/bash

hostlist=/shared/home/cycleadmin/healthchecks/hostlist
EXEPATH=/shared/home/cycleadmin/healthchecks/nccl/run_nccl_all_reduce.sh
OUTDIR=/shared/home/cycleadmin/healthchecks/nccl/out
#
if [ ! -d $OUTDIR ]; then
	   mkdir -p $OUTDIR
fi
cd $OUTDIR
src=$(tail -n1 $hostlist)
for line in $(<$hostlist); do
    dst=$line
    ${EXEPATH} $src $dst | tee ${src}_to_${dst}_nccl_allreduce.log_$$
    src=$dst
done
