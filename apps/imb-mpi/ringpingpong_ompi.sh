#!/bin/bash
set -o pipefail
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
mpi_options+=" -bind-to core"
mpi_options+=" -npernode 1 -np 2"

# affinity
numactl_options=" numactl --cpunodebind 0"

hostlist=$(pwd)/hosts.$PBS_JOBID

sort -u $PBS_NODEFILE > $hostlist

src=$(tail -n 1 $hostlist)
# -msglog 9:10 is for 512 and 1024 bytes message size only
for dst in $(<$hostlist); do
    $MPI_HOME/bin/mpirun -host $src,$dst \
        $mpi_options $numactl_options \
        $HPCX_MPI_TESTS_DIR/imb/IMB-MPI1 PingPong -msglog 9:10 > ${src}_to_${dst}_ringpingpong.$PBS_JOBID.log 2>&1
    src=$dst
done

# clean up
rm $hostlist

echo "Ring Ping Pong Results (1024 bytes)"
printf "%-20s %-20s %10s\n" "Source" "Destination" "Time [usec]"
grep "^         1024 " *_ringpingpong.$PBS_JOBID.log \
    | tr -s ' ' | cut -d ' ' -f 1,4 \
    | sed 's/_to_/ /g;s/_ringpingpong[^:]*://g' \
    | sort -nk 3 \
    | xargs printf "%-20s %-20s %10s\n" | tee output.log

