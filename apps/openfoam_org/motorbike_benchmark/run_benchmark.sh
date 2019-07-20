#!/bin/bash

INSTALL_DIR=/apps
RUN_DIR="$1"
CASE_NAME="$2"
NODES="$3"
PPN="$4"

source $INSTALL_DIR/OpenFOAM/setenv.sh

timestamp=$(date +%Y%m%d-%H%M%S)

cd $RUN_DIR
TARGET=${CASE_NAME}-${NODES}x${PPN}-benchmark
rsync -a ${CASE_NAME}-${NODES}x${PPN}/. ${TARGET}
cd $TARGET

foamDictionary -entry writeInterval -set 1000 system/controlDict
foamDictionary -entry runTimeModifiable -set "false" system/controlDict
foamDictionary -entry functions -set "{}" system/controlDict

cat $PBS_NODEFILE | sort -u > hostlist-$timestamp
HOSTFILE=hostlist-$timestamp
NP=$(($NODES * $PPN))

mpirun -np $NP -ppn $PPN -hostfile hostlist-$timestamp potentialFoam -parallel 2>&1 | tee log.potentialFoam-$timestamp
mpirun -np $NP -ppn $PPN -hostfile hostlist-$timestamp simpleFoam -parallel 2>&1 | tee log.simpleFoam-$timestamp

touch case.foam
