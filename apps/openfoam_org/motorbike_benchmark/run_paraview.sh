#!/bin/bash

INSTALL_DIR=/apps
NODES="$1"
PPN="$2"

source $INSTALL_DIR/OpenFOAM/setenv.sh

cat $PBS_NODEFILE | sort -u > hostlist
HOSTFILE=hostlist
NP=$(($NODES * $PPN))

mpirun -np $NP -ppn $PPN -hostfile hostlist $INSTALL_DIR/ParaView-5.6.1-osmesa-MPI-Linux-64bit/bin/pvserver

