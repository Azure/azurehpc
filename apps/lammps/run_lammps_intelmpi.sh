#!/bin/bash
DATA_DIR=/data
CORES=`cat $PBS_NODEFILE | wc -l`
PPN=`cat $PBS_NODEFILE | uniq -c | head -1 | awk '{ print $1 }'`
MPI_HOSTFILE=$PBS_NODEFILE

export lammps_case=in.lj
echo "downloading case ${lammps_case}..."

wget  "https://lammps.sandia.gov/inputs/${lammps_case}.txt" -O ${DATA_DIR}/${lammps_case}

source /opt/intel/impi/*/bin64/mpivars.sh
export MPI_ROOT=$I_MPI_ROOT
export I_MPI_FABRICS=shm:dapl
export I_MPI_DAPL_PROVIDER=ofa-v2-ib0
export I_MPI_DYNAMIC_CONNECTION=0
export I_MPI_FALLBACK_DEVICE=0
export OMP_NUM_THREADS=$CORES

echo "Running LAMMPS Benchmark case : [${lammps_case}] on ${CORES} cores"
mpirun -np $CORES -hostfile $MPI_HOSTFILE -ppn $PPN lmp -in ${DATA_DIR}/${lammps_case}
