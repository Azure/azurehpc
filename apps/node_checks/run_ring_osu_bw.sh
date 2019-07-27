#!/bin/bash
#
# Requires three parameters
# first paramter : full path to hostfile
# second parameter : full path to osu_bw executable
# third parameter : full path to output directory
#
module load gcc-8.2.0
module load mpi/mvapich2-2.3.1
#
hostlist=$1
EXEPATH=$2
OUTDIR=$3
#
if [ ! -d $OUTDIR ]; then
   mkdir -p $OUTDIR
fi
cd $OUTDIR
src=$(tail -n1 $hostlist)
for line in $(<$hostlist); do
    dst=$line
    mpirun -np 2 -hosts $src,$dst -env MV2_SHOW_CPU_BINDING 2 ${EXEPATH} | tee ${src}_to_${dst}_osu_bw.log_$$
    src=$dst
done
#
first_ip=$(head -1 $hostlist)
pattern=${first_ip:0:2}
grep 4194304 ${pattern}* | sort -n -k 2 | tee osu_bw_report.log_$$
