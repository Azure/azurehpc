#!/bin/bash
FILESYSTEM=${1:-/data}
SHARED_APP=${2:-/apps}

source /etc/profile # so we can load modules

module use ${SHARED_APP}/modulefiles
module load ior

AZHPC_VMSIZE=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2018-10-01" | jq -r '.compute.vmSize')
AZHPC_VMSIZE='standard_hb60rs'
export AZHPC_VMSIZE=${AZHPC_VMSIZE,,}
#echo "Running on $AZHPC_VMSIZE"
if [ "$AZHPC_VMSIZE" = "" ]; then
    echo "Unable to retrieve VM Size - Exiting"
    exit 1
fi

case "$AZHPC_VMSIZE" in
    standard_hb60rs | standard_hc44rs | standard_hb120rs_v2 )
        module load mpi/hpcx
        ;;
    *)
        module load mpi/mpich-3.2-x86_64
        ;;
esac

if [[ -n "$PBS_NODEFILE" ]]; then
    CORES=$(cat $PBS_NODEFILE | wc -l)
    NODES=$(cat $PBS_NODEFILE | sort -u)
    MPI_OPTS="-np $CORES --hostfile $PBS_NODEFILE"
fi

# Throughput test (N-N)
mpirun  -bind-to hwthread $MPI_OPTS $IOR_BIN/ior -a POSIX -v -i 3 -m -d 1 -B -e -F -r -w -t 32m -b 4G -o ${FILESYSTEM}/test.$(date +"%Y-%m-%d_%H-%M-%S") -O summaryFormat=JSON
sleep 2
# Throughput test (N-1)
mpirun  -bind-to hwthread $MPI_OPTS $IOR_BIN/ior -a POSIX -v -i 3 -m -d 1 -B -e -r -w -t 32m -b 4G -o ${FILESYSTEM}/test.$(date +"%Y-%m-%d_%H-%M-%S") -O summaryFormat=JSON
sleep 2
# IOPS test
mpirun -bind-to hwthread $MPI_OPTS $IOR_BIN/ior -a POSIX -v -i 3 -m -d 1 -B -e -F -r -w -t 4k -b 128M -o ${FILESYSTEM}/test.$(date +"%Y-%m-%d_%H-%M-%S") -O summaryFormat=JSON
