#!/bin/bash
CASE=${1##*/}
CASE_DIR=${1%$CASE}
THREADS=${2-1}
SHARED_ROOT=$3

# Set AZHPC_XXX environment variables
AZHPC_DATA=${SHARED_ROOT}/data
AZHPC_APPS=${SHARED_ROOT}/apps
AZHPC_APPLICATION=VPS2018
AZHPC_JOBID=$PBS_JOBID
AZHPC_SHARED_DIR=$AZHPC_DATA/$AZHPC_APPLICATION/$AZHPC_JOBID
AZHPC_SCRATCH_DIR=/mnt/resource/scratch/$AZHPC_JOBID

mkdir -p $AZHPC_SHARED_DIR
mkdir -p $AZHPC_SCRATCH_DIR

AZHPC_JOBDIR=$AZHPC_SCRATCH_DIR
cd $AZHPC_JOBDIR
AZHPC_MPI_HOSTFILE=hostfile
cat $PBS_NODEFILE > $AZHPC_MPI_HOSTFILE

# remove long domain name from hostfile
h=$(tail -n 1 $AZHPC_MPI_HOSTFILE)
d=${h#*.}
sed -i 's/.'$d'//g' $AZHPC_MPI_HOSTFILE


AZHPC_PPN=`cat $PBS_NODEFILE | uniq -c | head -1 | awk '{ print $1 }'`
AZHPC_VMSIZE=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2018-10-01" | jq -r '.compute.vmSize')
export AZHPC_VMSIZE=${AZHPC_VMSIZE,,}
AZHPC_CORES=`cat $PBS_NODEFILE | wc -l`

PKEY=$(grep -v -e 0000 -e 0x7fff --no-filename /sys/class/infiniband/mlx5_0/ports/1/pkeys/*)
PKEY=${PKEY/0x8/0x0}

source /etc/profile # so we can load modules
module use /usr/share/Modules/modulefiles
module use $AZHPC_APPS/modulefiles
module load ${AZHPC_APPLICATION}

module load mpi/impi
source $MPI_BIN/mpivars.sh

export PAMCRASH=$PAMHOME/pamcrash_safe/2018.01/Linux_x86_64/bin/pamcrash

PAM_MPI=impi-5.1.3
export MPI_OPTIONS="-f $AZHPC_MPI_HOSTFILE -perhost ${AZHPC_PPN} -genv I_MPI_FABRICS shm:ofa -genv I_MPI_DYNAMIC_CONNECTION 0 -genv I_MPI_FALLBACK_DEVICE 0"

echo "downloading case ${CASE}..."
start_time=$SECONDS
cp -r $CASE_DIR/* .
end_time=$SECONDS
download_time=$(($end_time - $start_time))
echo "Download time is ${download_time}"

echo "create the local working dir on all nodes"
mpirun -np ${AZHPC_CORES} -f $AZHPC_MPI_HOSTFILE -perhost 1 mkdir -p $AZHPC_SCRATCH_DIR

$PAMCRASH -np ${AZHPC_CORES} \
    -nt $THREADS \
    -lic CRASHSAF \
    -mpi $PAM_MPI \
    -mpidir $MPI_BIN \
    -mpiexe mpirun \
    -mpiext '$MPI_OPTIONS' \
    $CASE | tee stdout.log

echo "upload results"
start_time=$SECONDS
cp -r * $AZHPC_SHARED_DIR/
end_time=$SECONDS
upload_time=$(($end_time - $start_time))
echo "Upload time is ${upload_time}"

echo "Clean up local scratch files"
mpirun -np ${AZHPC_CORES} -f $AZHPC_MPI_HOSTFILE -perhost 1 rm -rf $AZHPC_SCRATCH_DIR
