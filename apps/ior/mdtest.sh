#!/bin/bash
FILESYSTEM=$1
SHARED_APP=${2:-/apps}

DIRECTORY=${FILESYSTEM}/testing
NUMFILES=10000

source /etc/profile # so we can load modules

export MODULEPATH=${SHARED_APP}/modulefiles:$MODULEPATH
module load gcc-8.2.0
# ior environment contains mdtest also.
module load ior

AZHPC_VMSIZE=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2018-10-01" | jq -r '.compute.vmSize')
export AZHPC_VMSIZE=${AZHPC_VMSIZE,,}

case "$AZHPC_VMSIZE" in
    standard_hb60rs | standard_hc44rs)
        module load mpi/mpich-3.3
        PKEY=$(grep -v -e 0000 -e 0x7fff --no-filename /sys/class/infiniband/mlx5_0/ports/1/pkeys/*)
        PKEY=${PKEY/0x8/0x0}
        mpi_options="-env UCX_IB_PKEY=$PKEY"
        ;;
    *)
        module load mpi/mpich-3.2-x86_64
        ;;
esac


# Metadata test
mpirun  -bind-to hwthread $mpi_options mdtest -n $NUMFILES -d $DIRECTORY -i 3 -u
