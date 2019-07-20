#!/bin/bash

RUN_DIR=/data

AZHPC_APPS=/apps
AZHPC_CORES=`cat $PBS_NODEFILE | wc -l`
AZHPC_PPN=`cat $PBS_NODEFILE | uniq -c | head -1 | awk '{ print $1 }'`

TUTORIAL=$1
SOLVER=$2
CASE_NAME=$3

soure /etc/profile
module use ${AZHPC_APPS}/modulefiles
module load OpenFOAM_6

cd $RUN_DIR
cp -r $WM_PROJECT_DIR/tutorials/$TUTORIAL/$SOLVER/$CASE_NAME $CASE_NAME
cd $CASE_NAME

./Allrun

