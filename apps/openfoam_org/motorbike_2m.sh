#!/bin/bash

RUN_DIR=/data
CASE_NAME=motorbike_scaled-${PBS_JOBID}

AZHPC_APPS=/apps
AZHPC_CORES=`cat $PBS_NODEFILE | wc -l`
AZHPC_PPN=`cat $PBS_NODEFILE | uniq -c | head -1 | awk '{ print $1 }'`

source /etc/profile
module use ${AZHPC_APPS}/modulefiles
module load OpenFOAM_6

cd $RUN_DIR
cp -r $WM_PROJECT_DIR/tutorials/incompressible/simpleFoam/motorBike $CASE_NAME
cd $CASE_NAME

cat $PBS_NODEFILE | sort -u > hostlist
HOSTFILE=hostlist

# increase blockmesh size
sed -i 's/(20 8 8)/(40 16 16)/g' system/blockMeshDict

# Determine X,Y,Z based on total cores
if [ "$(($AZHPC_PPN % 4))" == "0" ]; then
    X=$(($AZHPC_CORES / 4))
    Y=2
    Z=2
elif [ "$(($AZHPC_PPN % 6))" == "0" ]; then
    X=$(($AZHPC_CORES / 6))
    Y=3
    Z=2
elif [ "$(($AZHPC_PPN % 9))" == "0" ]; then
    X=$(($AZHPC_CORES / 9))
    Y=3
    Z=3
else
    echo "Incompataible value of PPN: $AZHPC_PPN. Try something that is divisable by 4,6, or 9"
    exit -1
fi
echo "X: $X, Y: $Y, Z: $Z"

# set up decomposition
sed -i "s/numberOfSubdomains 6;/numberOfSubdomains $AZHPC_CORES;/g" system/decomposeParDict
sed -i "s/(3 2 1);/(${X} ${Y} ${Z});/g" system/decomposeParDict

# update runParallel to add MPI flags
sed -i "s/runParallel\( *\([^ ]*\).*\)$/mpirun -np $AZHPC_CORES -ppn $AZHPC_PPN -hostfile hostlist \1 -parallel 2\>\&1 |tee log\.\2/g" Allrun

./Allrun

touch motorBike.foam
chmod -R 755 ${RUN_DIR}/${CASE_NAME}

