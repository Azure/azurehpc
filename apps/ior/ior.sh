#!/bin/bash
FILESYSTEM=$1
SHARED_APP=${2:-/apps}

source /etc/profile # so we can load modules

export MODULEPATH=${SHARED_APP}/modulefiles:$MODULEPATH
# GCC 8 is no longer provided with CentOS-HPC 7.7 image, it is now 9.2, but is this really needed ?
#module load gcc-8.2.0
module load ior

AZHPC_VMSIZE=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2018-10-01" | jq -r '.compute.vmSize')
export AZHPC_VMSIZE=${AZHPC_VMSIZE,,}
echo "Running on $AZHPC_VMSIZE"
if [ "$AZHPC_VMSIZE" = "" ]; then
    echo "unable to retrieve VM Size - Exiting"
    exit 1
fi

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

# Throughput test (N-N)
mpirun  -bind-to hwthread $mpi_options ior -a POSIX -v -z -i 3 -m -d 1 -B -e -F -r -w -t 32m -b 4G -o ${FILESYSTEM}/test.$(date +"%Y-%m-%d_%H-%M-%S")
sleep 2
# Throughput test (N-1)
mpirun  -bind-to hwthread $mpi_options ior -a POSIX -v -z -i 3 -m -d 1 -B -e -r -w -t 32m -b 4G -o ${FILESYSTEM}/test.$(date +"%Y-%m-%d_%H-%M-%S")
sleep 2
# IOPS test
mpirun -bind-to hwthread $mpi_options ior -a POSIX -v -z -i 3 -m -d 1 -B -e -F -r -w -t 4k -b 128M -o ${FILESYSTEM}/test.$(date +"%Y-%m-%d_%H-%M-%S")
