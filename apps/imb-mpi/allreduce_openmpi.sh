#!/bin/bash
source /etc/profile
module use /usr/share/Modules/modulefiles
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

num_ranks=$(wc -l <$PBS_NODEFILE)

mpirun --timeout 240 -hostfile $PBS_NODEFILE $mpi_options -np $num_ranks \
    $HPCX_MPI_TESTS_DIR/imb/IMB-MPI1 Allreduce -npmin $num_ranks \
    -iter 10000 \
    -msglog 3:4 -time 1000000 | tee output.log
