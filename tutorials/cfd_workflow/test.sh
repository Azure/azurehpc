#!/bin/bash

qstat
pbsnodes -avS
nodes=$(pbsnodes -a -F dsv -L -S | wc -l)
if [ "$nodes" = 0 ]; then
    echo "Error - No nodes in PBS"
    exit 1
fi
df -h

qsub -l select=2:ncpus=60:mpiprocs=60,place=scatter:excl -N OF_motorbike_2m $HOME/apps/openfoam_org/motorbike_2m.sh

qstat -aw

jobs=$(qstat | wc -l)
while [ "$jobs" != "0" ]; do
    qstat
    jobs=$(qstat | wc -l)
    sleep 30
done

# TODO add any error detection in the scripts
tail -n 100 OF_motorbike_2m.o0
tail -n 100 OF_motorbike_2m.e0
