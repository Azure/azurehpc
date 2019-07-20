#!/bin/bash

#PBS -N OPM_norne
#PBS -l select=1:ncpus=30:mpiprocs=30
#PBS -koed
#PBS -joe
#PBS -l walltime=1800

OMPI_ROOT=openmpi-4.0.1
SHARED_APP=/apps
SHARED_DATA=/data
source /etc/profile # so we can load modules
module use $SHARED_APP/modulefiles
module load opm/v2019.04
module load gcc-8.2.0
module load mpi/$OMPI_ROOT

export OPAL_PREFIX=$MPI_HOME
export PATH=$PATH:$MPI_HOME/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$MPI_HOME/lib:/usr/lib64:/usr/local/lib:$SHARED_APP/opm/boost_1_70_0/stage/lib:$SHARED_APP/opm/ecl/lib64
export C_INCLUDE_PATH=${C_INCLUDE_PATH-}:/usr/local/include:$SHARED_APP/opm/boost_1_70_0:$SHARED_APP/opm/ecl/include

CORES=`cat $PBS_NODEFILE | wc -l`

get_ib_pkey()
{
    key0=$(cat /sys/class/infiniband/mlx5_0/ports/1/pkeys/0)
    key1=$(cat /sys/class/infiniband/mlx5_0/ports/1/pkeys/1)
  
    if [ $(($key0 - $key1)) -gt 0 ]; then
        export IB_PKEY=$key0
    else
        export IB_PKEY=$key1
    fi
  
    export UCX_IB_PKEY=$(printf '0x%04x' "$(( $IB_PKEY & 0x0FFF ))")
}

get_ib_pkey

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
        -x UCX_IB_PKEY=$UCX_IB_PKEY \
        -x LD_LIBRARY_PATH \
        -wd $PWD \
        $OPM_BIN_DIR/flow --parameter-file=./params 2>&1 
