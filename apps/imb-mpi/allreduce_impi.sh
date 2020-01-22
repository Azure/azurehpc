#!/bin/bash

# setup Intel MPI environment for Infiniband
source /etc/profile # so we can load modules
module load mpi/impi-2019
source $MPI_BIN/mpivars.sh -ofi_internal

num_ranks=$(wc -l <$PBS_NODEFILE)
mpi_options="-genv I_MPI_FABRICS shm:ofi"

mpirun -hostfile $PBS_NODEFILE $mpi_options -np $num_ranks \
        IMB-MPI1 Allreduce -npmin $num_ranks \
        -iter 10000 \
        -msglog 3:4 -time 1000000 | tee output.log
