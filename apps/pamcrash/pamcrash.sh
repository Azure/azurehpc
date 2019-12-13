#!/bin/bash
CASE=${1##*/}
CASE_DIR=${1%$CASE}
THREADS=${2-1}
MPI=${3-impi2018}
SHARED_ROOT=$4

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
# convert to uppercase as pamworld is case sensitive when using -cf option
# but not the prefix which remains in lowercase in cycle
sed -i 's/.*/\U&/g' $AZHPC_MPI_HOSTFILE
sed -i 's/IP/ip/g' $AZHPC_MPI_HOSTFILE


AZHPC_PPN=`cat $PBS_NODEFILE | uniq -c | head -1 | awk '{ print $1 }'`
AZHPC_CORES=`cat $PBS_NODEFILE | wc -l`
AZHPC_NODES=$(sort -u < $PBS_NODEFILE | wc -l)

AZHPC_VMSIZE=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2018-10-01" | jq -r '.compute.vmSize')
export AZHPC_VMSIZE=${AZHPC_VMSIZE,,}

PKEY=$(grep -v -e 0000 -e 0x7fff --no-filename /sys/class/infiniband/mlx5_0/ports/1/pkeys/*)
PKEY=${PKEY/0x8/0x0}

source /etc/profile
module use /usr/share/Modules/modulefiles
module use $AZHPC_APPS/modulefiles
module load ${AZHPC_APPLICATION}

case $MPI in
    impi2018)
        module load mpi/impi
        source $MPI_BIN/mpivars.sh
        PAM_MPI=impi-5.1.3
        PAM_OPTIONS="-np ${AZHPC_CORES}"
        mpi_options="-f $AZHPC_MPI_HOSTFILE -perhost ${AZHPC_PPN}"
        mpi_options+=" -genv I_MPI_FABRICS shm:dapl -genv I_MPI_DYNAMIC_CONNECTION 0 -genv I_MPI_FALLBACK_DEVICE 0"
        mpi_options+=" -genv I_MPI_DAPL_TRANSLATION_CACHE 0"
        mpi_options+=" -genv I_MPI_DAPL_UD enable"
        mpi_options+=" -genv MALLOC_MMAP_MAX_ 0 -genv MALLOC_TRIM_THRESHOLD_ -1 -genv KMP_BLOCKTIME 0"
        mpi_options+=" -genv I_MPI_DEBUG 6"
        if [ "$THREADS" != "1" ]; then
            mpi_options+=" -genv I_MPI_PIN_DOMAIN omp"
        fi
        MPI_SCRATCH_OPTIONS="-f $AZHPC_MPI_HOSTFILE -perhost 1"
    ;;
    impi2019)
        module load mpi/impi-2019
        source $MPI_BIN/mpivars.sh
        PAM_MPI=impi-5.1.3
        PAM_OPTIONS="-np ${AZHPC_CORES}"
        mpi_options="-f $AZHPC_MPI_HOSTFILE -perhost ${AZHPC_PPN}"
        #mpi_options+=" -genv I_MPI_COLL_EXTERNAL 1 -genv FI_PROVIDER mlx"
        mpi_options+=" -genv I_MPI_FABRICS shm:ofi -genv I_MPI_DYNAMIC_CONNECTION 0 -genv I_MPI_FALLBACK_DEVICE 0"
        mpi_options+=" -genv MALLOC_MMAP_MAX_ 0 -genv MALLOC_TRIM_THRESHOLD_ -1 -genv KMP_BLOCKTIME 0"
        mpi_options+=" -genv I_MPI_DEBUG 6"
        MPI_SCRATCH_OPTIONS="-f $AZHPC_MPI_HOSTFILE -perhost 1"
    ;;
    ompi)
        module load mpi/hpcx
        PAM_MPI=openmpi-1.10.5
        PAM_OPTIONS="-cf $AZHPC_MPI_HOSTFILE"
        ln -s $MPI_HOME/lib/libmpi.so $AZHPC_SHARED_DIR/libmpi.so.12
        ln -s $MPI_HOME/lib/libmpi_usempi.so $AZHPC_SHARED_DIR/libmpi_usempi.so.5
        ln -s $MPI_HOME/lib/libmpi_mpifh.so $AZHPC_SHARED_DIR/libmpi_mpifh.so.12
        export LD_LIBRARY_PATH=$AZHPC_SHARED_DIR:${LD_LIBRARY_PATH}
        numa_domains="$(numactl -H |grep available|cut -d' ' -f2)"
        AZHPC_PPR=$(( ($AZHPC_PPN + $numa_domains - 1) / $numa_domains ))

        mpi_options=" -np $AZHPC_CORES"
        #mpi_options+=" --mca pml ucx -mca osc ucx"
        mpi_options+=" -x UCX_NET_DEVICES=mlx5_0:1 -x UCX_IB_PKEY=$PKEY -x UCX_LOG_LEVEL=ERROR"

        # Enable HCOLL
        #mpi_options+=" --mca coll_hcoll_enable 1 -x coll_hcoll_np=0 -x HCOLL_MAIN_IB=mlx5_0:1"

        mpi_options+=" -x MXM_SHM_RNDV_THRESH=32768"
        mpi_options+=" -x MALLOC_MMAP_MAX_=0 -x MALLOC_TRIM_THRESHOLD_=-1 -x KMP_BLOCKTIME=0"
        mpi_options+=" --map-by ppr:$AZHPC_PPR:numa"
        mpi_options+=" -x LD_LIBRARY_PATH"
        if [ "$THREADS" = "1" ]; then
            mpi_options+=" -bind-to core"
        else
            mpi_options+=" -bind-to numa"
        fi
        mpi_options+=" -report-bindings --display-allocation -v"
        MPI_SCRATCH_OPTIONS="-hostfile $AZHPC_MPI_HOSTFILE -npernode 1"
        MPI_BIN=$MPI_HOME/bin
    ;;
esac

export MPI_OPTIONS=$mpi_options
export PAMCRASH=$PAMHOME/pamcrash_safe/2018.01/Linux_x86_64/bin/pamcrash

echo "downloading case ${CASE}..."
start_time=$SECONDS
cp -r $CASE_DIR/* .
end_time=$SECONDS
download_time=$(($end_time - $start_time))
echo "Download time is ${download_time}"

echo "create the local working dir on all nodes"
$MPI_BIN/mpirun -np ${AZHPC_NODES} $MPI_SCRATCH_OPTIONS mkdir -p $AZHPC_SCRATCH_DIR

$PAMCRASH $PAM_OPTIONS \
    -nt $THREADS \
    -lic CRASHSAF \
    -mpi $PAM_MPI \
    -mpidir $MPI_BIN \
    -mpiexe mpirun \
    -mpiext '$MPI_OPTIONS' \
    -debug 2 \
    $CASE | tee stdout.log

echo "upload results"
start_time=$SECONDS
cp -r * $AZHPC_SHARED_DIR/
end_time=$SECONDS
upload_time=$(($end_time - $start_time))
echo "Upload time is ${upload_time}"

echo "Clean up local scratch files"
$MPI_BIN/mpirun -np ${AZHPC_NODES} $MPI_SCRATCH_OPTIONS rm -rf $AZHPC_SCRATCH_DIR

case $MPI in
    ompi)
        unlink $AZHPC_SHARED_DIR/libmpi.so.12
        unlink $AZHPC_SHARED_DIR/libmpi_usempi.so.5
        unlink $AZHPC_SHARED_DIR/libmpi_mpifh.so.12
    ;;
esac
