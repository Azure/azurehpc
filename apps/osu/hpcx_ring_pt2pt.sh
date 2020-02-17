# osu_latency osu_bw osu_bibw
set -o pipefail
source /etc/profile
module use /usr/share/Modules/modulefiles
module load mpi/hpcx

AZHPC_MPI_HOSTFILE=$PBS_NODEFILE

PKEY=`cat /sys/class/infiniband/mlx5_0/ports/1/pkeys/* | grep -v 0000 | grep -v 0x7fff`
PKEY=`echo "${PKEY/0x8/0x0}"`
echo "PKEY=$PKEY"

mpi_options+=" --mca btl self"

# Use UCX
mpi_options+=" --mca pml ucx --mca osc ucx"
mpi_options+=" -x UCX_NET_DEVICES=mlx5_0:1 -x UCX_IB_PKEY=$PKEY -x UCX_LOG_LEVEL=error"
# Enable HCOLL
mpi_options+=" --mca coll_hcoll_enable 1 -x coll_hcoll_np=0 -x HCOLL_MAIN_IB=mlx5_0:1"
# Tune collectives
mpi_options+=" -x HCOLL_ENABLE_MCAST_ALL=1 -x HCOLL_MCAST_NP=0 -x HCOLL_CONTEXT_CACHE_ENABLE=1"

mpi_options+=" -x LD_LIBRARY_PATH"
mpi_options+=" -bind-to core"
mpi_options+=" -npernode 1 -np 2"
mpi_options+=" --report-bindings --display-allocation -v"

# affinity
numactl_options=" numactl --cpunodebind 0"

for BENCH in osu_latency osu_bw osu_bibw; do
    src=$(tail -n1 $AZHPC_MPI_HOSTFILE)
    for line in $(<$AZHPC_MPI_HOSTFILE); do
        dst=$line
        $MPI_HOME/bin/mpirun -host $src,$dst \
            $mpi_options $numactl_options \
            $HPCX_OSU_DIR/${BENCH} | tee ${src}_to_${dst}_${BENCH}.log
        src=$dst
    done
done

