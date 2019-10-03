#!/bin/bash

for x in 1 2 4 8 16 32 64 96 128; do
    for y in 36 40 44; do
        qsub -l select=$x:ncpus=$y:mpiprocs=$y:ompthreads=1,place=scatter:excl -v LIC_SRV=headnode  apps/radioss/run_T10M.pbs
        if [ "$x" -gt 8 ]; then
            z1=$(($y/2))
            qsub -l select=$x:ncpus=$z1:mpiprocs=$z1:ompthreads=2,place=scatter:excl -v LIC_SRV=headnode  apps/radioss/run_T10M.pbs 
            z2=$(($y/4))
            qsub -l select=$x:ncpus=$z2:mpiprocs=$z2:ompthreads=4,place=scatter:excl -v LIC_SRV=headnode  apps/radioss/run_T10M.pbs
        fi
    done
done
