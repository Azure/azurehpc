#!/bin/bash
CASE=${1##*/}
CASE_DIR=${1%$CASE}
SHARED_ROOT=${2-/}
ITER=$3
PROFILE=$4

APP_VERSION=2.5.1

# Set AZHPC_XXX environment variables
AZHPC_DATA=${SHARED_ROOT}data
AZHPC_APPS=${SHARED_ROOT}apps
AZHPC_APPLICATION=prolb
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
echo "running on $AZHPC_VMSIZE"
AZHPC_CORES=`cat $PBS_NODEFILE | wc -l`

PKEY=$(grep -v -e 0000 -e 0x7fff --no-filename /sys/class/infiniband/mlx5_0/ports/1/pkeys/*)
PKEY=${PKEY/0x8/0x0}

source /etc/profile # so we can load modules

module use /usr/share/Modules/modulefiles
module use $AZHPC_APPS/modulefiles
module load gcc-9.2.0
module load ${AZHPC_APPLICATION}_${APP_VERSION}
module load mpi/hpcx

if [ -n "${PROFILE}" ]; then
    export HPCX_IPM_DIR=${HPCX_DIR}/ompi/tests/ipm-2.0.6
    export IPM_KEYFILE=${HPCX_IPM_DIR}/etc/ipm_key_mpi
    export IPM_LOG=FULL
    export LD_PRELOAD=${HPCX_IPM_DIR}/lib/libipm.so

    BARRIER=0  # Barrier is important to have a clean picture of the MPI API commands
    # BARRIER==1 doesn't works here
    if [[ "$BARRIER" == "1" ]]; then
        export IPM_ADD_BARRIER_TO_REDUCE=1
        export IPM_ADD_BARRIER_TO_ALLREDUCE=1
        export IPM_ADD_BARRIER_TO_GATHER=1
        export IPM_ADD_BARRIER_TO_ALL_GATHER=1
        export IPM_ADD_BARRIER_TO_ALLTOALL=1
        export IPM_ADD_BARRIER_TO_ALLTOALLV=1
        export IPM_ADD_BARRIER_TO_BROADCAST=1
        export IPM_ADD_BARRIER_TO_SCATTER=1
        export IPM_ADD_BARRIER_TO_SCATTERV=1
        export IPM_ADD_BARRIER_TO_GATHERV=1
        export IPM_ADD_BARRIER_TO_ALLGATHERV=1
    fi
fi

numa_domains="$(numactl -H |grep available|cut -d' ' -f2)"
AZHPC_PPR=$(( ($AZHPC_PPN + $numa_domains - 1) / $numa_domains ))
AZHPC_PPS=$(( ($AZHPC_PPN) / 2 ))


printenv

echo "downloading case ${CASE}..."
start_time=$SECONDS
cp -r $CASE_DIR/* $AZHPC_JOBDIR
end_time=$SECONDS
download_time=$(($end_time - $start_time))
echo "Download time is ${download_time}"

case $AZHPC_VMSIZE in
    standard_hc44rs|standard_hb60rs)
        # self is required by PROLB
        mpi_options+=" -mca btl self"

        # Use UCX
        mpi_options+=" --mca pml ucx -mca osc ucx"
        mpi_options+=" -x UCX_NET_DEVICES=mlx5_0:1 -x UCX_IB_PKEY=$PKEY"

        #mpi_options+=" -x UCX_ZCOPY_THRESH=262144"

        # Enable HCOLL
        mpi_options+=" --mca coll_hcoll_enable 1 -x coll_hcoll_np=0 -x HCOLL_MAIN_IB=mlx5_0:1"
    ;;
    standard_hb120rs_v2)
        #mpi_options+=" --mca pml ucx -mca osc ucx"
        #mpi_options+=" --mca pml yalla"
        #mpi_options+=" --mca coll_hcoll_enable 1 -x coll_hcoll_np=0"
        #mpi_options+=" -x HCOLL_CONTEXT_CACHE_ENABLE=1"
        #mpi_options+=" -x UCX_DC_MLX5_RNR_TIMEOUT=2000.00us -x UCX_DC_MLX5_RNR_RETRY_COUNT=20"
    ;;
esac

mpi_options+=" -x UCX_ZCOPY_THRESH=262144"
mpi_options+=" -x UCX_LOG_LEVEL=ERROR"
mpi_options+=" --map-by ppr:$AZHPC_PPR:numa"
#mpi_options+=" --map-by ppr:$AZHPC_PPN:socket"
#mpi_options+=" --map-by ppr:$AZHPC_PPN:node"
mpi_options+=" -x LD_LIBRARY_PATH"
mpi_options+=" --bind-to core"
mpi_options+=" --report-bindings --display-allocation -v"

if [ -n "${LD_PRELOAD}" ]; then
    mpi_options+=" -x LD_PRELOAD"
fi

# Use 98% of the memory
total_mem=$(free -m | grep Mem: | xargs | cut -d' ' -f2)
memory=$(( ($total_mem * 98 / 100) / $AZHPC_PPN ))
echo "memory per rank=$memory"

iter_option=""
if [ -n "$ITER" ]; then
    iter_option=" -add $ITER"
fi
echo "iter_option=$iter_option"
echo $mpi_options

# Keep tuning files separate for each VM Type
TUNING_DIR=$AZHPC_DATA/$AZHPC_APPLICATION/$AZHPC_VMSIZE/
if [ ! -d ${TUNING_DIR} ]; then
    mkdir -p $TUNING_DIR
    cp $PROLB_HOME/schemes/* $TUNING_DIR
fi
SCHEME_DIR=$TUNING_DIR

$MPI_HOME/bin/mpirun $mpi_options \
    -hostfile $AZHPC_MPI_HOSTFILE \
    -np $AZHPC_CORES \
    $PROLB_HOME/bin/lbsolver -np $AZHPC_CORES \
                             -s $SCHEME_DIR \
                             -tuning $TUNING_DIR \
                             -m $memory $iter_option \
                             -p $AZHPC_JOBDIR/$CASE | tee prolb.log

end_time=$SECONDS
task_time=$(($end_time - $start_time))

if [ -n "${PROFILE}" ]; then
    xmlfile=$(ls -atr *.xml | tail -n1)
    $HPCX_IPM_DIR/bin/ipm_parse -full $xmlfile
fi

output=prolb.log
if [ -f "${output}" ]; then

    mpi_version=$($MPI_HOME/bin/mpirun -version | head -n 1)
    nb_iter=$(grep "################# current time is 0/" ${output} | cut -d'/' -f2 | cut -d' ' -f1 | xargs)

    if [ "$APP_VERSION" = "2.5.1" ]; then
        total_cpu_time=$(grep "LBsolver normal termination" ${output} | cut -d' ' -f10 | cut -d'-' -f1 | xargs)
    else
        total_cpu_time=$(grep "LBsolver normal termination" ${output} | cut -d' ' -f7 | xargs)
    fi

    FluidLinks_time=$(grep "FluidLinks         |" ${output} | cut -d'|' -f3 | cut -d'=' -f1 | xargs)
    Migrate_time=$(grep "Migrate            |" ${output} | cut -d'|' -f3 | cut -d'=' -f1 | xargs)
    Solver_time=$(grep "Solver             |" ${output} | cut -d'|' -f3 | cut -d'=' -f1 | xargs)

    cat <<EOF >$AZHPC_APPLICATION.json
    {
    "mpi_version": "$mpi_version",
    "version": "$APP_VERSION",
    "model": "$CASE",
    "nb_iter": $nb_iter,
    "fluidlinks_time": $FluidLinks_time,
    "migrate_time": $Migrate_time,
    "solver_time": $Solver_time,
    "total_cpu_time": $total_cpu_time,
    "task_time": $task_time,
    "download_time": $download_time
    }
EOF
fi
