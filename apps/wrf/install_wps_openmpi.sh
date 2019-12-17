#!/bin/bash
SHARED_APP=/apps
APP_NAME=wps
APP_VERSION=4.1
WRF_VERSION=4.1.3

cd $SHARED_APP
wget https://github.com/wrf-model/WPS/archive/v${APP_VERSION}.tar.gz
tar xvf v${APP_VERSION}.tar.gz

spack load netcdf-fortran^openmpi
spack load netcdf^openmpi
spack load hdf5^openmpi
spack load perl
spack load openmpi
module load gcc-9.2.0

export HDF5=$(spack location -i hdf5^openmpi)
export NETCDF=$(spack location -i netcdf-fortran^openmpi)
export WRF_DIR=${SHARED_APP}/WRF-${WRF_VERSION}

cd WPS-${APP_VERSION}
./configure << EOF
3
EOF

./compile
