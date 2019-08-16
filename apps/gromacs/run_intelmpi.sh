#!/bin/bash

APPLICATION="GROMACS"
SHARED_DIR=/apps
OUTPUT_DIR=/data
CORES=`cat $PBS_NODEFILE | wc -l`
PPN=`cat $PBS_NODEFILE | uniq -c | head -1 | awk '{ print $1 }'`
MPI_HOSTFILE=$PBS_NODEFILE


GMX_VERSION=2019.3
INSTALL_DIR=${SHARED_DIR}/gromacs-${GMX_VERSION}
OUTPUT_FILE=${OUTPUT_DIR}/gromacs.log
NSTEPS=10000
NTOMP=1

echo "downloading case ${casename} from ${package}..."
wget -q http://www.prace-ri.eu/UEABS/GROMACS/1.2/${package} -O ${package}
tar xvf ${package} -C $SHARED_DIR

source /opt/intel/impi/*/bin64/mpivars.sh
export MPI_ROOT=$I_MPI_ROOT
export I_MPI_FABRICS=shm:ofa
export I_MPI_FALLBACK_DEVICE=0
export I_MPI_STATS=ipm

mpirun \
    -ppn $PPN -np $CORES --hostfile $MPI_HOSTFILE \
    ${INSTALL_DIR}/bin/gmx_mpi mdrun \
    -s $SHARED_DIR/${casename} -maxh 1.00 -resethway -noconfout -nsteps ${NSTEPS} -g ${OUTPUT_FILE} -ntomp ${NTOMP} -pin on -cpt -1


if [ -f "${OUTPUT_FILE}" ]; then
    total_wall_time=$(grep "Time:" ${OUTPUT_FILE} | awk -F ' ' '{print $3}')
    total_cpu_time=$(grep "Time:" ${OUTPUT_FILE} | awk -F ' ' '{print $2}')
    ns_per_day=$(grep "Performance:" ${OUTPUT_FILE} | awk -F ' ' '{print $2}')
    hour_per_ns=$(grep "Performance:" ${OUTPUT_FILE} | awk -F ' ' '{print $3}')

    cat <<EOF >$APPLICATION.json
    {
    "version": "$GMX_VERSION",
    "model": "$casename",
    "total_wall_time": $total_wall_time,
    "total_cpu_time": $total_cpu_time,
    "ns_per_day": $ns_per_day,
    "hour_per_ns": $hour_per_ns,
    "nsteps": $NSTEPS,
    "ntomp": $NTOMP
    }
EOF
fi