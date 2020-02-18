#!/bin/bash
# MODE: ring (one to one node only), half (one to each one way only)
MODE=${1-ring}
set -o pipefail
source /etc/profile
module use /usr/share/Modules/modulefiles
module load mpi/hpcx

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

hostlist=$(pwd)/hosts.$PBS_JOBID
sort -u $PBS_NODEFILE > $hostlist
# remove .internal.cloudapp.net from node names
sed -i 's/.internal.cloudapp.net//g' $hostlist

case $MODE in
    ring) # one to neighbour
        src=$(tail -n 1 $hostlist)
        for dst in $(<$hostlist); do
            $MPI_HOME/bin/mpirun -host $src,$dst \
                $mpi_options $numactl_options \
                $HPCX_OSU_DIR/${BENCH} > ${src}_to_${dst}_osu.$PBS_JOBID.log 2>&1
            src=$dst
        done
    ;;
    half) # one to each one way
        cp $hostlist desthosts.$PBS_JOBID
        for src in $(<$hostlist); do
            SED_STR="s/$src//g"
            sed -i $SED_STR desthosts.$PBS_JOBID
            for dest in $(<desthosts.$PBS_JOBID); do
                $MPI_HOME/bin/mpirun -host $src,$dst \
                    $mpi_options $numactl_options \
                    $HPCX_OSU_DIR/${BENCH} > ${src}_to_${dst}_osu.$PBS_JOBID.log 2>&1
            done
        done
        rm desthosts.$PBS_JOBID
    ;;
esac

# clean up
rm $hostlist

echo "Ring Bandwidth Results (4194304 bytes)"
printf "%-20s %-20s %10s\n" "Source" "Destination" "Bandwidth [MB/s]"
grep "^4194304" *_osu.$PBS_JOBID.log \
    | tr -s ' ' | cut -d ' ' -f 1,2 \
    | sed 's/_to_/ /g;s/_osu.[^*]*:4194304//g' \
    | sort -nk 3 \
    | xargs printf "%-20s %-20s %10s\n" | tee output.log

