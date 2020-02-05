#!/bin/bash

AZHPC_DATA=/lustre/
AZHPC_APPS=/lustre/apps
AZHPC_APPLICATION=prolb

AZHPC_VMSIZE=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2018-10-01" | jq -r '.compute.vmSize')
export AZHPC_VMSIZE=${AZHPC_VMSIZE,,}

source /etc/profile # so we can load modules

module use /usr/share/Modules/modulefiles
module use $AZHPC_APPS/modulefiles

module load ${AZHPC_APPLICATION}_2.5.1
module load mpi/openmpi

TUNING_DIR=$AZHPC_DATA/$AZHPC_APPLICATION/$AZHPC_VMSIZE/

echo "POST_PROCESS MERGE_TUNING D3Q19DRT $TUNING_DIR TO ${TUNING_DIR}D3Q19DRT.tun" > ${TUNING_DIR}tuning.txt

$MPI_HOME/bin/mpirun -np 1 $PROLB_HOME/bin/lbsolver -np 1 -i ${TUNING_DIR}tuning.txt
