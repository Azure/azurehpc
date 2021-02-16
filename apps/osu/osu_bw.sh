#!/bin/bash
# MODE: ring (one to one node only), half (one to each one way only)
MODE=${1-ring}
set -o pipefail
source /etc/profile.d/modules.sh
module use /usr/share/Modules/modulefiles
module load mpi/hpcx

[[ -n $PBS_NODEFILE ]] && { ISPBS=true; JOBID=$PBS_JOBID; }
[[ -n $SLURM_NODELIST ]] && { ISSLURM=true; JOBID=$SLURM_JOBID; }

mpi_options+=" -x LD_LIBRARY_PATH"
mpi_options+=" -bind-to core"
mpi_options+=" --report-bindings --display-allocation -v"

if [[ "$ISPBS" = true ]]; then
    mpi_options+=" -npernode 1 -np 2"
    hostlist=$(pwd)/hosts.$JOBID
    sort -u $PBS_NODEFILE > $hostlist
    # remove .internal.cloudapp.net from node names
    #sed -i 's/.internal.cloudapp.net//g' $hostlist
elif [[ "$ISSLURM" = true ]]; then
    scontrol show hostname $SLURM_NODELIST > $(pwd)/hosts.$JOBID
    hostlist=$(pwd)/hosts.$JOBID
fi

# affinity
numactl_options=" numactl --cpunodebind 0"

BENCH=osu_bw

case $MODE in
    ring) # one to neighbour
        src=$(tail -n 1 $hostlist)
        for dst in $(<$hostlist); do
            $MPI_HOME/bin/mpirun -host $src,$dst \
                $mpi_options $numactl_options \
                $HPCX_OSU_DIR/${BENCH} > ${src}_to_${dst}_osu.$JOBID.log 2>&1
            src=$dst
        done
    ;;
    half) # one to each one way
        cp $hostlist desthosts.$JOBID
        for src in $(<$hostlist); do
            # delete the first line
            sed -i '1d' desthosts.$JOBID
            for dst in $(<desthosts.$JOBID); do
                $MPI_HOME/bin/mpirun -host $src,$dst \
                    $mpi_options $numactl_options \
                    $HPCX_OSU_DIR/${BENCH} > ${src}_to_${dst}_osu.$JOBID.log 2>&1
            done
        done
        rm desthosts.$JOBID
    ;;
esac

# clean up
rm $hostlist

echo "Ring Bandwidth Results (4194304 bytes)"
printf "%-20s %-20s %10s\n" "Source" "Destination" "Bandwidth [MB/s]"
grep "^4194304" *_osu.$JOBID.log \
    | tr -s ' ' | cut -d ' ' -f 1,2 \
    | sed 's/_to_/ /g;s/_osu.[^*]*:4194304//g' \
    | sort -nk 3 \
    | xargs printf "%-20s %-20s %10s\n" | tee output.log

