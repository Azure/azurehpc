#!/bin/bash
SKU_TYPE=${1:-$SKU_TYPE}
APP_NAME=wrf
APP_VERSION=4.1.3
SKU_TYPE=${SKU_TYPE:-hbv2}
SHARED_APP=${SHARED_APP:-/apps}
MODULE_DIR=${SHARED_APP}/modulefiles/${SKU_TYPE}/${APP_NAME}
MODULE_NAME=${APP_VERSION}-mvapich2
APP_DIR=$SHARED_APP/${SKU_TYPE}/${APP_NAME}-mvapich2
APPS_WRF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function create_modulefile {
mkdir -p ${MODULE_DIR}
cat << EOF >> ${MODULE_DIR}/${MODULE_NAME}
#%Module
set              wrfversion        ${APP_VERSION}
set              WRFROOT           ${APP_DIR}/WRF-\$wrfversion
setenv           WRFROOT           ${APP_DIR}/WRF-\$wrfversion

append-path      PATH              \$WRFROOT/main
EOF
}

sudo yum install -y jasper-devel libpng-devel python3

source /etc/profile
module use ${SHARED_APP}/modulefiles
module load spack/spack
source $SPACK_SETUP_ENV

echo "spack install"
spack install  netcdf-fortran+mpi ^netcdf~parallel-netcdf ^hdf5+fortran %gcc@9.2.0 ^mvapich2@2.3.2

echo "get WRF source"
mkdir -p ${APP_DIR}
cd ${APP_DIR}
if [ ! -e v${APP_VERSION}.tar.gz ]; then
    wget -q https://github.com/wrf-model/WRF/archive/v${APP_VERSION}.tar.gz
    tar xf v${APP_VERSION}.tar.gz
fi

echo "spack load"
spack load netcdf-fortran^mvapich2
spack load netcdf^mvapich2
spack load hdf5^mvapich2
spack load perl
echo "module load"
module load mpi/mvapich2-2.3.2
module load gcc-9.2.0

export HDF5=$(spack location -i hdf5^mvapich2)
echo "HDF5=$HDF5"
export NETCDF=$(spack location -i netcdf-fortran^mvapich2)
echo "NETCDF=$NETCDF"

NETCDF_C=$(spack location -i netcdf^mvapich2)
echo "NETCDF_C=$NETCDF_C"
ln -sf $NETCDF_C/include/* $NETCDF/include/
ln -sf $NETCDF_C/lib/* $NETCDF/lib/
ln -sf $NETCDF_C/lib/pkgconfig/* $NETCDF/lib/pkgconfig

cd WRF-${APP_VERSION}
echo "apply patch"
patch -t -p0 < ${APPS_WRF_DIR}/WRFV4.0-rsl-8digit.patch

./configure << EOF
34

EOF

./compile -j 16 em_real || exit 1

create_modulefile
