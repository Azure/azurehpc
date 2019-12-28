#!/bin/bash

APP_NAME=wps
APP_VERSION=4.1
SKU_TYPE=hb
SHARED_APP=/apps
WRF_VERSION=4.1.3
APP_DIR=${SHARED_APP}/${SKU_TYPE}/${APP_NAME}-mvapich2

sudo yum install -y jasper-devel
sudo yum install -y libpng-devel

mkdir -p ${APP_DIR}
cd ${APP_DIR}
wget https://github.com/wrf-model/WPS/archive/v${APP_VERSION}.tar.gz
tar xvf v${APP_VERSION}.tar.gz

source ${SPACK_ROOT}/share/spack/setup-env.sh

spack load netcdf-fortran^mvapich2
spack load netcdf^mvapich2
spack load hdf5^mvapich2
spack load perl
module load mpi/mvapich2-2.3.2
module load gcc-9.2.0

export HDF5=$(spack location -i hdf5^mvapich2)
export NETCDF=$(spack location -i netcdf-fortran^mvapich2)
export WRF_DIR=${SHARED_APP}/${SKU_TYPE}/wrf-mvapich2/WRF-${WRF_VERSION}

cd WPS-${APP_VERSION}
./configure << EOF
3
EOF

./compile
