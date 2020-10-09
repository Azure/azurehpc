#!/bin/bash

APP_NAME=wrf
APP_VERSION=4.1.5
SKU_TYPE=${SKU_TYPE:-hbv2}
SHARED_APP=${SHARED_APP:-/apps}
INTEL_COMPILER_INSTALL_DIR=${INTEL_COMPILER_INSTALL_DIR:-/apps/intel}
INTEL_MPI_PACKAGE_VERSION=${INTEL_MPI_PACKAGE_VERSION:-2020.1.217}
INTEL_COMPILER_PACKAGE_VERSION=${INTEL_COMPILER_PACKAGE_VERSION:-2019.6.324}
INTEL_COMPILER_VERSION=${INTEL_COMPILER_VERSION:-19.0.8.324}
MODULE_DIR=${SHARED_APP}/modulefiles/${SKU_TYPE}/${APP_NAME}
MODULE_NAME=${APP_VERSION}-omp-intel
APP_DIR=$SHARED_APP/${SKU_TYPE}/${APP_NAME}-omp-intel
APPS_WRF_DIR=`pwd`

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

sudo yum install -y jasper-devel
sudo yum install -y libpng-devel

module load gcc-9.2.0
source ${INTEL_COMPILER_INSTALL_DIR}/compilers_and_libraries_${INTEL_COMPILER_PACKAGE_VERSION}/linux/bin/compilervars.sh intel64
source /opt/intel/compilers_and_libraries_${INTEL_MPI_PACKAGE_VERSION}/linux/mpi/intel64/bin/mpivars.sh
spack compiler add
spack install --dirty netcdf-fortran+mpi ^hdf5+fortran %intel@${INTEL_COMPILER_VERSION} ^intel-mpi@${INTEL_MPI_PACKAGE_VERSION}
source ${SPACK_ROOT}/share/spack/setup-env.sh

mkdir -p ${APP_DIR}
cd ${APP_DIR}
wget https://github.com/wrf-model/WRF/archive/v${APP_VERSION}.tar.gz
tar xvf v${APP_VERSION}.tar.gz

spack load netcdf-fortran%intel@${INTEL_COMPILER_VERSION}^intel-mpi
spack load hdf5+fortran%intel@${INTEL_COMPILER_VERSION}^intel-mpi
spack load perl%intel@${INTEL_COMPILER_VERSION}

export HDF5=$(spack location -i hdf5+fortran%intel@${INTEL_COMPILER_VERSION}^intel-mpi)
export NETCDF=$(spack location -i netcdf-fortran%intel@${INTEL_COMPILER_VERSION}^intel-mpi)

NETCDF_C=$(spack location -i netcdf-c%intel@${INTEL_COMPILER_VERSION}^numactl^intel-mpi)
ln -sf $NETCDF_C/include/* $NETCDF/include/
ln -sf $NETCDF_C/lib/* $NETCDF/lib/
ln -sf $NETCDF_C/lib/pkgconfig/* $NETCDF/lib/pkgconfig

cd WRF-${APP_VERSION}
patch -p0 < ${APPS_WRF_DIR}/WRFV4.0-rsl-8digit.patch

./configure << EOF
67

EOF

sed -i 's/CFLAGS_LOCAL    =       -w -O3 -ip -xHost -fp-model fast=2 -no-prec-div -no-prec-sqrt -ftz -no-multibyte-chars -xCORE-AVX2/CFLAGS_LOCAL    =       -w -O3 -ip -fp-model fast=2 -no-prec-div -no-prec-sqrt -ftz -no-multibyte-chars -march=core-avx2/' ./configure.wrf
sed -i 's/LDFLAGS_LOCAL   =       -ip -xHost -fp-model fast=2 -no-prec-div -no-prec-sqrt -ftz -align all -fno-alias -fno-common -xCORE-AVX2/LDFLAGS_LOCAL   =       -ip -fp-model fast=2 -no-prec-div -no-prec-sqrt -ftz -align all -fno-alias -fno-common -march=core-avx2/' ./configure.wrf
sed -i 's/FCBASEOPTS_NO_G =       -ip -fp-model precise -w -ftz -align all -fno-alias $(FORMAT_FREE) $(BYTESWAPIO) -xHost -fp-model fast=2 -no-heap-arrays -no-prec-div -no-prec-sqrt -fno-common -xCORE-AVX2/FCBASEOPTS_NO_G =       -ip -w -ftz -align all -fno-alias $(FORMAT_FREE) $(BYTESWAPIO) -fp-model fast=2 -no-heap-arrays -no-prec-div -no-prec-sqrt -fno-common -march=core-avx2/' ./configure.wrf

./compile -j 16 em_real

create_modulefile
