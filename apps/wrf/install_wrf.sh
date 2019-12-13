#!/bin/bash
SHARED_APP=/apps
MODULE_DIR=${SHARED_APP}/modulefiles
APP_NAME=wrf
APP_VERSION=4.1.3
MODULE_NAME=${APP_NAME}_${APP_VERSION}

function create_modulefile {
mkdir -p ${MODULE_DIR}
cat << EOF >> ${MODULE_DIR}/${MODULE_NAME}
#%Module
set              wrfversion        ${APP_VERSION}
set              WRFROOT           ${SHARED_APP}/WRF-\$wrfversion
setenv           WRFROOT           ${SHARED_APP}/WRF-\$wrfversion

append-path      PATH              \$WRFROOT/main
EOF
}

sudo yum install -y jasper-devel
sudo yum install -y libpng-devel

spack install  netcdf-fortran+mpi ^netcdf~parallel-netcdf ^hdf5+fortran %gcc@9.2.0 ^mvapich2@2.3.2

cd $SHARED_APP
wget https://github.com/wrf-model/WRF/archive/v${APP_VERSION}.tar.gz
tar xvf v${APP_VERSION}.tar.gz

spack load netcdf-fortran
spack load netcdf
spack load hdf5
spack load perl
spack load mvapich2
module load gcc-9.2.0

export HDF5=$(spack location -i hdf5)
export NETCDF=$(spack location -i netcdf-fortran)

NETCDF_C=$(spack location -i netcdf)
ln -sf $NETCDF_C/include/* $NETCDF/include/
ln -sf $NETCDF_C/lib/* $NETCDF/lib/
ln -sf $NETCDF_C/lib/pkgconfig/* $NETCDF/lib/pkgconfig

cd WRF-${APP_VERSION}
./configure << EOF
34

EOF

./compile -j 16 em_real

create_modulefile
