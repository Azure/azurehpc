#!/bin/bash

NP=$1

source /etc/profile.d/modules.sh
export MODULEPATH=$MODULEPATH:/apps/modulefiles

module load gcc-9.2.0
module load mpi/impi_2018.4.274
module load io500-app

mpirun -np $NP ior -o /localnvme/testfile -C -Q 1 -g -G 271 -k -e -t 1M -b 2G -F -w -D 300 -O stoneWallingWearOut=1 -a POSIX

echo 3 | sudo tee /proc/sys/vm/drop_caches 

mpirun -np $NP ior -o /localnvme/testfile -C -Q 1 -g -G 271 -k -e -t 1M -b 2G -F -r -R -a POSIX

rm -rf /localnvme/testfile*
