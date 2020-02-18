#!/bin/bash
MPI=$1
set -o pipefail
source /etc/profile
module use /usr/share/Modules/modulefiles

num_ranks=$(wc -l <$PBS_NODEFILE)

case $MPI in
    impi2018)
        module load mpi/impi
        source $MPI_BIN/mpivars.sh
        export I_MPI_FABRICS="shm:ofa"
        export I_MPI_FALLBACK_DEVICE=0
        export I_MPI_DEBUG=4
        mpi_options="-hostfile $PBS_NODEFILE -np $num_ranks"
        IMB_ROOT=$MPI_BIN
    ;;
    impi2019)
        module load mpi/impi-2019
        source $MPI_BIN/mpivars.sh -ofi_internal
        export I_MPI_FABRICS="shm:ofi"
        export I_MPI_FALLBACK_DEVICE=0
        export I_MPI_DEBUG=4
        mpi_options="-hostfile $PBS_NODEFILE -np $num_ranks"
        IMB_ROOT=$MPI_BIN
    ;;
    ompi)
        module load mpi/hpcx

        # PKEY is no longer needed on CentOS 7.7+
        # TODO : use cat /etc/centos-release to retrieve version and set PKEY if lower than 7.6
        PKEY=`cat /sys/class/infiniband/mlx5_0/ports/1/pkeys/* | grep -v 0000 | grep -v 0x7fff`
        PKEY=`echo "${PKEY/0x8/0x0}"`
        echo "PKEY=$PKEY"

        mpi_options="--mca btl ^vader,tcp,openib,uct -mca pml ucx"
        mpi_options+=" --mca opal_warn_on_missing_libcuda 0"
        mpi_options+=" --map-by core"
        #mpi_options+=" --report-bindings --display-allocation"
        mpi_options+=" -x UCX_IB_PKEY=$PKEY"
        mpi_options+=" -x UCX_NET_DEVICES=mlx5_0:1 -x UCX_TLS=ud_x,sm,self"

        # Enable HCOLL
        mpi_options+=" --mca coll_hcoll_enable 1 -x coll_hcoll_np=0 -x HCOLL_MAIN_IB=mlx5_0:1"
        # Tune collectives
        mpi_options+=" -x HCOLL_ENABLE_MCAST_ALL=1 -x HCOLL_MCAST_NP=0 -x HCOLL_CONTEXT_CACHE_ENABLE=1"

        mpi_options+=" -hostfile $PBS_NODEFILE -np $num_ranks"
        # affinity
        numactl_options=" numactl --cpunodebind 0"
        IMB_ROOT=$HPCX_MPI_TESTS_DIR/imb
    ;;
esac

mpirun $mpi_options \
    $IMB_ROOT/IMB-MPI1 Allreduce -npmin $num_ranks \
    -iter 10000 \
    -msglog 3:4 -time 1000000 | tee output.log
