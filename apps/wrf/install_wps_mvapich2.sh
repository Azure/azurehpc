#!/bin/bash
SKU_TYPE=${1:-$SKU_TYPE}
APP_NAME=wps
APP_VERSION=4.1
SKU_TYPE=${SKU_TYPE:-hbv2}
SHARED_APP=${SHARED_APP:-/apps}
WRF_VERSION=4.1.3
MVAPICH2_VER=2.3.3
APP_DIR=${SHARED_APP}/${SKU_TYPE}/${APP_NAME}-mvapich2

sudo yum install -y jasper-devel libpng-devel python3

echo "get WPS source"
mkdir -p ${APP_DIR}
cd ${APP_DIR}
if [ ! -e v${APP_VERSION}.tar.gz ]; then
    wget -q https://github.com/wrf-model/WPS/archive/v${APP_VERSION}.tar.gz
    tar xf v${APP_VERSION}.tar.gz
fi

echo "spack load"
source /usr/share/Modules/init/bash
module use ${SHARED_APP}/modulefiles
module load spack/spack
source $SPACK_SETUP_ENV

spack load netcdf-fortran^mvapich2
spack load netcdf^mvapich2
spack load hdf5^mvapich2
spack load perl
echo "module load"
module load mpi/mvapich2-${MVAPICH2_VER}
module load gcc-9.2.0

export HDF5=$(spack location -i hdf5^mvapich2)
echo "HDF5=$HDF5"
export NETCDF=$(spack location -i netcdf-fortran^mvapich2)
echo "NETCDF=$NETCDF"
export WRF_DIR=${SHARED_APP}/${SKU_TYPE}/wrf-mvapich2/WRF-${WRF_VERSION}
echo "WRF_DIR=$WRF_DIR"

cd WPS-${APP_VERSION}
./configure << EOF
3
EOF

./compile || exit 1
