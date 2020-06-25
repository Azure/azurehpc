#!/bin/bash
#SBATCH --nodes=2
#SBATCH --tasks-per-node=1
#SBATCH --output=osu_%A.out
#SBATCH --job-name=osu

# MODE: ring (one to one node only), half (one to each one way only)
MODE=${1-ring}
set -o pipefail
source /etc/profile
module use /usr/share/Modules/modulefiles
module load mpi/hpcx

mpi_options+=" -x LD_LIBRARY_PATH"
mpi_options+=" -bind-to core"
mpi_options+=" --report-bindings --display-allocation -v"

# affinity
numactl_options=" numactl --cpunodebind 0"

BENCH=osu_bw

scontrol show hostname $SLURM_NODELIST > $(pwd)/hosts.$SLURM_JOBID
hostlist=$(pwd)/hosts.$SLURM_JOBID

case $MODE in
    ring) # one to neighbour
        src=$(tail -n 1 $hostlist)
        for dst in $(<$hostlist); do
            $MPI_HOME/bin/mpirun -host $src,$dst \
                $mpi_options $numactl_options \
                $HPCX_OSU_DIR/${BENCH} > ${src}_to_${dst}_osu.$SLURM_JOBID.log 2>&1
            src=$dst
        done
    ;;
    half) # one to each one way
        cp $hostlist desthosts.$SLURM_JOBID
        for src in $(<$hostlist); do
            # delete the first line
            sed -i '1d' desthosts.$SLURM_JOBID
            for dst in $(<desthosts.$SLURM_JOBID); do
                $MPI_HOME/bin/mpirun -host $src,$dst \
                    $mpi_options $numactl_options \
                    $HPCX_OSU_DIR/${BENCH} > ${src}_to_${dst}_osu.$SLURM_JOBID.log 2>&1
            done
        done
        rm desthosts.$SLURM_JOBID
    ;;
esac

# clean up
rm $hostlist

echo "Ring Bandwidth Results (4194304 bytes)"
printf "%-20s %-20s %10s\n" "Source" "Destination" "Bandwidth [MB/s]"
grep "^4194304" *_osu.$SLURM_JOBID.log \
    | tr -s ' ' | cut -d ' ' -f 1,2 \
    | sed 's/_to_/ /g;s/_osu.[^*]*:4194304//g' \
    | sort -nk 3 \
    | xargs printf "%-20s %-20s %10s\n"

