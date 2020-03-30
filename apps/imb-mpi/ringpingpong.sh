#!/bin/bash
MPI=$1
MODE=${2-ring}
set -o pipefail
source /etc/profile
module use /usr/share/Modules/modulefiles

case $MPI in
    impi2018)
        module load mpi/impi
        #source $MPI_BIN/mpivars.sh
        export I_MPI_FABRICS="shm:ofa"
        export I_MPI_FALLBACK_DEVICE=0
        export I_MPI_DEBUG=4
        mpi_options="-np 2 -ppn 1"
        host_option="-hosts"
        if [ -z $MPI_BIN ]; then
            IMB_ROOT=$I_MPI_ROOT/intel64/bin
        else
            IMB_ROOT=$MPI_BIN
        fi
    ;;
    impi2019)
        module load mpi/impi-2019
        #source $MPI_BIN/mpivars.sh -ofi_internal
        export I_MPI_FABRICS="shm:ofi"
        #export I_MPI_FALLBACK_DEVICE=0
        export I_MPI_DEBUG=4
        export FI_PROVIDER=verbs
        mpi_options="-np 2 -ppn 1"
        host_option="-hosts"
        if [ -z $MPI_BIN ]; then
            IMB_ROOT=$I_MPI_ROOT/intel64/bin
        else
            IMB_ROOT=$MPI_BIN
        fi
    ;;
    ompi)
        module load mpi/hpcx

        mpi_options=" --map-by core"
        mpi_options+=" -bind-to core"
        mpi_options+=" -npernode 1 -np 2"
        host_option="-host"

        IMB_ROOT=$HPCX_MPI_TESTS_DIR/imb
    ;;
esac
# affinity
numactl_options=" numactl --cpunodebind 0"

hostlist=$(pwd)/hosts.$PBS_JOBID

sort -u $PBS_NODEFILE > $hostlist
# remove .internal.cloudapp.net from node names
sed -i 's/.internal.cloudapp.net//g' $hostlist

case $MODE in
    ring) # one to neighbour
        src=$(tail -n 1 $hostlist)
        # -msglog 9:10 is for 512 and 1024 bytes message size only
        for dst in $(<$hostlist); do
            mpirun $host_option $src,$dst \
                $mpi_options $numactl_options \
                $IMB_ROOT/IMB-MPI1 PingPong -msglog 9:10 > ${src}_to_${dst}_ringpingpong.$PBS_JOBID.log
            src=$dst
        done
    ;;
    half) # one to each one way
        cp $hostlist desthosts.$PBS_JOBID
        for src in $(<$hostlist); do
            # delete the first line
            sed -i '1d' desthosts.$PBS_JOBID
            for dst in $(<desthosts.$PBS_JOBID); do
                mpirun $host_option $src,$dst \
                    $mpi_options $numactl_options \
                    $IMB_ROOT/IMB-MPI1 PingPong -msglog 9:10 > ${src}_to_${dst}_ringpingpong.$PBS_JOBID.log
            done
        done
        rm desthosts.$PBS_JOBID
    ;;
esac
# clean up
rm $hostlist

echo "Ring Ping Pong Results (1024 bytes)"
printf "%-20s %-20s %10s\n" "Source" "Destination" "Time [usec]"
grep "^         1024 " *_ringpingpong.$PBS_JOBID.log \
    | tr -s ' ' | cut -d ' ' -f 1,4 \
    | sed 's/_to_/ /g;s/_ringpingpong[^:]*://g' \
    | sort -nk 3 \
    | xargs printf "%-20s %-20s %10s\n" | tee output.log

