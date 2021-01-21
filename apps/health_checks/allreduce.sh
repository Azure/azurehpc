#!/bin/bash

set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo -e "\nRequired parameters:"
    echo -e "   - Hostfile path"
    echo -e "   - Number of ranks per host\n"
    exit 1
fi

module load mpi/hpcx

hostsfile=$1
ppn=$2

outdir="Allreduce_$(date '+%Y%m%d_%H%M%S')"

mkdir -p ${outdir}

for target in $(<$hostsfile); do
    mpirun --host ${target}:${ppn} -np ${ppn} --mca pml ucx --mca btl ^vader,tcp,openib,uct \
    ${PMIX_INSTALL_PREFIX}/tests/imb/IMB-MPI1 Allreduce \
    -iter 10000 -npmin 120 -msglog 3:4 -time 1000000 &> ${outdir}/allreduce_${target}.out

    echo -n "${target}   "
    awk 'c!=0 && --c==0; /Benchmarking/{c=6}' ${outdir}/allreduce_${target}.out
done

