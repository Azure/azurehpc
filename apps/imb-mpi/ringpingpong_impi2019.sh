#!/bin/bash
set -o pipefail
# setup Intel MPI environment for Infiniband
source /etc/profile
module load mpi/impi-2019
source $MPI_BIN/mpivars.sh -ofi_internal

hostlist=$(pwd)/hosts.$PBS_JOBID

sort -u $PBS_NODEFILE > $hostlist

export I_MPI_FABRICS="shm:ofi"
export I_MPI_FALLBACK_DEVICE=0
export I_MPI_DEBUG=4

src=$(tail -n 1 $hostlist)
# -msglog 10:10 is for 512 and 1024 bytes message size only
for dst in $(<$hostlist); do
    mpirun -np 2 -ppn 1 -hosts $src,$dst IMB-MPI1 PingPong -msglog 9:10 > ${src}_to_${dst}_ringpingpong.$PBS_JOBID.log 2>&1
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
    | xargs printf "%-20s %-20s %10s\n"
