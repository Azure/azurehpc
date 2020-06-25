#!/bin/bash
#SBATCH --nodes=2
#SBATCH --tasks-per-node=1
#SBATCH --job-name=pingpong
#SBATCH --output=pingpong_%A.out

MPI=${1-impi2018}
MODE=${2-ring}
set -o pipefail

case $MPI in
    impi2016)
        source /opt/intel/impi/5.1.3.223/bin64/mpivars.sh
        export I_MPI_FABRICS="shm:dapl"
        export I_MPI_FALLBACK_DEVICE=0
        export I_MPI_DAPL_PROVIDER=ofa-v2-ib0
        export I_MPI_DEBUG=4
        host_option="-hosts"
        if [ -z $MPI_BIN ]; then
            IMB_ROOT=$I_MPI_ROOT/intel64/bin
        else
            IMB_ROOT=$MPI_BIN
        fi
    ;;
    impi2018)
        source /etc/profile
        module use /usr/share/Modules/modulefiles
        module load mpi/impi
        export I_MPI_FABRICS="shm:ofa"
        export I_MPI_FALLBACK_DEVICE=0
        export I_MPI_DEBUG=4
        host_option="-hosts"
        if [ -z $MPI_BIN ]; then
            IMB_ROOT=$I_MPI_ROOT/intel64/bin
        else
            IMB_ROOT=$MPI_BIN
        fi
    ;;
    impi2019)
        source /etc/profile
        module use /usr/share/Modules/modulefiles
        module load mpi/impi-2019
        export I_MPI_FABRICS="shm:ofi"
        export I_MPI_DEBUG=4
        export FI_PROVIDER=verbs
        host_option="-hosts"
        if [ -z $MPI_BIN ]; then
            IMB_ROOT=$I_MPI_ROOT/intel64/bin
        else
            IMB_ROOT=$MPI_BIN
        fi
    ;;
    ompi)
        source /etc/profile
        module use /usr/share/Modules/modulefiles
        module load mpi/hpcx

        mpi_options=" --map-by core"
        mpi_options+=" -bind-to core"
        host_option="-host"

        IMB_ROOT=$HPCX_MPI_TESTS_DIR/imb
    ;;
esac

# affinity
numactl_options=" numactl --cpunodebind 0"

scontrol show hostname $SLURM_NODELIST > $(pwd)/hosts.$SLURM_JOBID
hostlist=$(pwd)/hosts.$SLURM_JOBID

case $MODE in
    ring) # one to neighbour
        src=$(tail -n 1 $hostlist)
        # -msglog 9:10 is for 512 and 1024 bytes message size only
	for dst in $(<$hostlist); do
            mpirun $host_option $src,$dst \
                $numactl_options \
                $IMB_ROOT/IMB-MPI1 PingPong -msglog 9:10 > ${src}_to_${dst}_ringpingpong.$SLURM_JOBID.log
            src=$dst
        done
    ;;
    half) # one to each one way
        cp $hostlist desthosts.$SLURM_JOBID
        for src in $(<$hostlist); do
            # delete the first line
            sed -i '1d' desthosts.$SLURM_JOBID
            for dst in $(<desthosts.$SLURM_JOBID); do
                mpirun $host_option $src,$dst \
                    $numactl_options \
                    $IMB_ROOT/IMB-MPI1 PingPong -msglog 9:10 > ${src}_to_${dst}_ringpingpong.$SLURM_JOBID.log
            done
        done
        rm desthosts.$SLURM_JOBID
    ;;
esac

# clean up
rm $hostlist

echo "Ring Ping Pong Results (1024 bytes)"
printf "%-20s %-20s %10s\n" "Source" "Destination" "Time [usec]"
grep "^         1024 " *_ringpingpong.$SLURM_JOBID.log \
    | tr -s ' ' | cut -d ' ' -f 1,4 \
    | sed 's/_to_/ /g;s/_ringpingpong[^:]*://g' \
    | sort -nk 3 \
    | xargs printf "%-20s %-20s %10s\n"

