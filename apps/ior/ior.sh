#!/bin/bash
FILESYSTEM=${FILESYSTEM:-/data}
SHARED_APP=${SHARED_APP:-/apps}

source /etc/profile # so we can load modules

export MODULEPATH=${SHARED_APP}/modulefiles:$MODULEPATH
module use /apps/modulefiles
module load ior

AZHPC_VMSIZE=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2018-10-01" | jq -r '.compute.vmSize')
export AZHPC_VMSIZE=${AZHPC_VMSIZE,,}
#echo "Running on $AZHPC_VMSIZE"
if [ "$AZHPC_VMSIZE" = "" ]; then
    echo "unable to retrieve VM Size - Exiting"
    exit 1
fi

case "$AZHPC_VMSIZE" in
    standard_hb60rs | standard_hc44rs | standard_hb120rs_v2 )
        module load mpi/hpcx-v2.5.0
        ;;
    *)
        module load mpi/mpich-3.2-x86_64
        ;;
esac

CORES=$(cat $PBS_NODEFILE | wc -l)
NODES=$(cat $PBS_NODEFILE | sort -u)

# Throughput test (N-N)
mpirun  -bind-to hwthread -np $CORES --hostfile $PBS_NODEFILE /apps/ior/bin/ior -a POSIX -v -z -i 3 -m -d 1 -B -e -F -r -w -t 32m -b 4G -o ${FILESYSTEM}/test.$(date +"%Y-%m-%d_%H-%M-%S") -O summaryFormat=JSON
sleep 2
# Throughput test (N-1)
mpirun  -bind-to hwthread -np $CORES --hostfile $PBS_NODEFILE /apps/ior/bin/ior -a POSIX -v -z -i 3 -m -d 1 -B -e -r -w -t 32m -b 4G -o ${FILESYSTEM}/test.$(date +"%Y-%m-%d_%H-%M-%S") -O summaryFormat=JSON
sleep 2
# IOPS test
mpirun -bind-to hwthread -np $CORES --hostfile $PBS_NODEFILE /apps/ior/bin/ior -a POSIX -v -z -i 3 -m -d 1 -B -e -F -r -w -t 4k -b 128M -o ${FILESYSTEM}/test.$(date +"%Y-%m-%d_%H-%M-%S") -O summaryFormat=JSON