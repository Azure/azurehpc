#!/bin/bash

CASE_NAME="$1"
NODES="$2"
PPN="$3"

source $HOME/OpenFOAM/setenv.sh
cd $HOME/${CASE_NAME}-${NODES}x${PPN}

timestamp=$(date +%Y%m%d-%H%M%S)

mpi_options=()
mpi_options+=(-report-bindings)
mpi_options+=(-wd $PWD)
mpi_options+=($(env |grep FOAM | cut -d'=' -f1 | sed 's/^/-x /g' | tr '\n' ' ') -x MPI_BUFFER_SIZE)

echo "${mpi_options[@]}"

mpirun "${mpi_options[@]}" -hostfile $PBS_NODEFILE potentialFoam -parallel 2>&1 | tee log.potentialFoam-$timestamp
mpirun "${mpi_options[@]}" -hostfile $PBS_NODEFILE simpleFoam -parallel 2>&1 | tee log.simpleFoam-$timestamp

