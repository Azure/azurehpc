#!/bin/bash
  
hostlist=/shared/home/cycleadmin/healthchecks/hostlist
EXEPATH=/shared/home/cycleadmin/healthchecks/ib_lat/run_ib_write_lat_2N.sh
OUTDIR=/shared/home/cycleadmin/healthchecks/ib_lat/out
#
if [ ! -d $OUTDIR ]; then
mkdir -p $OUTDIR
fi
cd $OUTDIR
src=$(tail -n1 $hostlist)
for line in $(<$hostlist); do
    dst=$line
    ${EXEPATH} $src $dst | tee ${src}_to_${dst}_ib_write_lat.log_$$
    src=$dst
done
