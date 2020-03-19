#!/bin/bash

#PBS -N OPM_norne
#PBS -l select=1:ncpus=30:mpiprocs=30
#PBS -koed
#PBS -joe
#PBS -l walltime=1800

OMPI_ROOT=openmpi-4.0.2
SHARED_APP=/apps
SHARED_DATA=/data
source /etc/profile # so we can load modules
module use $SHARED_APP/modulefiles
module load opm/v2019.04
module load gcc-9.2.0
module load mpi/$OMPI_ROOT

export OPAL_PREFIX=$MPI_HOME
export PATH=$PATH:$MPI_HOME/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$MPI_HOME/lib:/usr/lib64:/usr/local/lib:$SHARED_APP/opm/boost_1_70_0/stage/lib:$SHARED_APP/opm/ecl/lib64
export C_INCLUDE_PATH=${C_INCLUDE_PATH-}:/usr/local/include:$SHARED_APP/opm/boost_1_70_0:$SHARED_APP/opm/ecl/include

CORES=`cat $PBS_NODEFILE | wc -l`

PKEY=$(grep -v -e 0000 -e 0x7fff --no-filename /sys/class/infiniband/mlx5_0/ports/1/pkeys/*)
PKEY=${PKEY/0x8/0x0}

cd $SHARED_DATA/opm-data/norne

echo "Running norne" 

mpirun  -np $CORES \
        -hostfile $PBS_NODEFILE \
        --map-by numa \
        --bind-to core \
        --report-bindings \
        -mca pml ucx \
        -mca btl self,vader,openib \
        -x UCX_NET_DEVICES=mlx5_0:1 \
        -x UCX_IB_PKEY=$PKEY \
        -x LD_LIBRARY_PATH \
        -wd $PWD \
        $OPM_BIN_DIR/flow --parameter-file=./params 2>&1 
