#!/bin/bash
SKU_TYPE=${1:-$SKU_TYPE}
SKU_TYPE=${SKU_TYPE:-hbv2}
SHARED_APP=${SHARED_APP:-/apps}

source /etc/profile.d/modules.sh
export MODULEPATH=${SHARED_APP}/modulefiles/${SKU_TYPE}:$MODULEPATH

echo "module load spack"
module use ${SHARED_APP}/modulefiles
module load spack/spack
source $SPACK_SETUP_ENV

echo "spack load"
spack load netcdf-fortran^openmpi
spack load hdf5^openmpi
spack load perl

echo "module load"
module use /usr/share/Modules/modulefiles
module load mpi/openmpi-4.0.5
module load gcc-9.2.0
module load wps/4.1-openmpi
module load wrf/4.1.5-openmpi

module list