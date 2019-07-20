#!/bin/bash

INSTALL_DIR=/apps
RUN_DIR="$1"
CASE_NAME="$2"
BLOCKMESH_DIMENSIONS="$3"

source $INSTALL_DIR/OpenFOAM/setenv.sh

cd $RUN_DIR
cp -r $WM_PROJECT_DIR/tutorials/incompressible/simpleFoam/motorBike $CASE_NAME
cd $CASE_NAME

cat $PBS_NODEFILE | sort -u > hostlist
HOSTFILE=hostlist
NODES=$(cat hostlist | wc -l)
CORES_PER_NODE=$(cat /proc/cpuinfo | grep processor | wc -l)
X_PER_NODE=$(($CORES_PER_NODE / 4))
PPN=$(($X_PER_NODE * 4))
NP=$(($NODES * $PPN))

foamDictionary \
    -entry castellatedMeshControls.maxGlobalCells \
    -set 200000000 \
    system/snappyHexMeshDict

foamDictionary \
    -entry blocks \
    -set "( hex ( 0 1 2 3 4 5 6 7 ) ( $BLOCKMESH_DIMENSIONS ) simpleGrading ( 1 1 1 ) )" \
    system/blockMeshDict

# set up decomposition
X=$(($NODES * $X_PER_NODE))
Y=2
Z=2

foamDictionary \
    -entry numberOfSubdomains \
    -set $NP \
    system/decomposeParDict

foamDictionary \
    -entry hierarchicalCoeffs.n \
    -set "($X $Y $Z)" \
    system/decomposeParDict

# Copy motorbike surface from resources directory
cp $WM_PROJECT_DIR/tutorials/resources/geometry/motorBike.obj.gz constant/triSurface/
surfaceFeatures 2>&1 | tee log.surfaceFeatures
blockMesh 2>&1 | tee log.blockMesh
decomposePar -copyZero 2>&1 | tee log.decomposePar
mpirun -np $NP -ppn $PPN -hostfile hostlist snappyHexMesh -parallel -overwrite 2>&1 | tee log.snappyHexMesh
reconstructParMesh -constant
rm -rf ./processor*
renumberMesh -constant -overwrite 2>&1 | tee log.renumberMesh
