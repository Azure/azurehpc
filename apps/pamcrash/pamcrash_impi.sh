#!/bin/bash
CASE=$1
CASE_DIR=$2
THREADS=${3-1}

# Set AZHPC_XXX environment variables
AZHPC_DATA=/data
AZHPC_APPS=/apps
AZHPC_APPLICATION=VPS2018
AZHPC_JOBID=$PBS_JOBID
AZHPC_SHARED_DIR=$AZHPC_DATA/$AZHPC_APPLICATION/$PBS_JOBID
mkdir -p $AZHPC_SHARED_DIR
AZHPC_JOBDIR=$AZHPC_SHARED_DIR
cd $AZHPC_JOBDIR
AZHPC_MPI_HOSTLIST=$(cat $PBS_NODEFILE)
AZHPC_MPI_HOSTFILE=$AZHPC_JOBDIR/hostfile
cat $PBS_NODEFILE > $AZHPC_MPI_HOSTFILE

AZHPC_PPN=`cat $PBS_NODEFILE | uniq -c | head -1 | awk '{ print $1 }'`
AZHPC_VMSIZE=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2018-10-01" | jq -r '.compute.vmSize')
export AZHPC_VMSIZE=${AZHPC_VMSIZE,,}
AZHPC_CORES=`cat $PBS_NODEFILE | wc -l`

PKEY=$(grep -v -e 0000 -e 0x7fff --no-filename /sys/class/infiniband/mlx5_0/ports/1/pkeys/*)
PKEY=${PKEY/0x8/0x0}

source /etc/profile # so we can load modules
module use /usr/share/Modules/modulefiles
module use $AZHPC_APPS/modulefiles
module load gcc-9.2.0
module load ${AZHPC_APPLICATION}
module load mpi/impi_2019

export PAMCRASH=$PAMHOME/pamcrash_safe/2018.01/Linux_x86_64/bin/pamcrash

export MPI_DIR=$MPI_BIN
PAM_MPI=impi-5.1.3
export MPI_OPTIONS="-hosts $MPI_HOSTLIST -perhost ${PPN} -genv I_MPI_FABRICS shm:ofa -genv I_MPI_DYNAMIC_CONNECTION 0 -genv I_MPI_FALLBACK_DEVICE 0"

echo "downloading case ${CASE}..."
start_time=$SECONDS
cp -r $CASE_DIR/* $AZHPC_JOBDIR
end_time=$SECONDS
download_time=$(($end_time - $start_time))
echo "Download time is ${download_time}"

$PAMCRASH -np ${AZHPC_CORES} \
    -nt $THREADS \
    -lic CRASHSAF \
    -mpi $PAM_MPI \
    -mpiexe mpirun \
    -mpidir $MPI_DIR \
    -mpiext '$MPI_OPTIONS' \
    $CASE.pc

