#!/bin/bash

CASE_NAME="$1"
BLOCKMESH_DIMENSIONS="$2"

source $HOME/OpenFOAM/setenv.sh

cd $HOME
cp -r $WM_PROJECT_DIR/tutorials/incompressible/simpleFoam/motorBike $CASE_NAME
cd $CASE_NAME

foamDictionary \
    -entry castellatedMeshControls.maxGlobalCells \
    -set 200000000 \
    system/snappyHexMeshDict

foamDictionary \
    -entry blocks \
    -set "( hex ( 0 1 2 3 4 5 6 7 ) ( $BLOCKMESH_DIMENSIONS ) simpleGrading ( 1 1 1 ) )" \
    system/blockMeshDict

# set up decomposition
X=6
Y=5
Z=4
NP=$(($X * $Y * $Z))

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
mpirun -np $NP snappyHexMesh -parallel -overwrite 2>&1 | tee log.snappyHexMesh
reconstructParMesh -constant
rm -rf ./processor*
renumberMesh -constant -overwrite 2>&1 | tee log.renumberMesh
