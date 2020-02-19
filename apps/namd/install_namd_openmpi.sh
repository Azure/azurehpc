#!/bin/bash
#
# Relevant environmental variables
#
# SKU_TYPE = hb, hc or hbv2 (default hbv2)
# NAMD_SOURCE_TAR_GZ_LOC, location of NAMD_2.13_Source.tar.gz source code (default hpcuser home dir)
# NAMD_SMP, set to "smp" if you want to build the smp version (default build non smp version)
# NAMD_MEMOPT, set to "--with-memopt" if you want to build memopt enabled version (default : memopt is disabled) 
#
#
APP_NAME=NAMD
APP_VERSION=2.13
SHARED_APP=/apps
NAMD_ARCH=Linux-x86_64-g++
SKU_TYPE=${SKU_TYPE:-hbv2}
MODULE_DIR=${SHARED_APP}/modulefiles/${SKU_TYPE}/${APP_NAME}
APP_TYPE=openmpi-gcc7.4
MODULE_NAME=${APP_VERSION}-${APP_TYPE}
APP_DIR=$SHARED_APP/${SKU_TYPE}/${APP_NAME}-${APP_TYPE}
NAMD_SOURCE_NAME=${APP_NAME}_${APP_VERSION}_Source

NAMD_SOURCE_TAR_GZ_LOC=${NAMD_SOURCE_TAR_GZ_LOC:-~hpcuser}

if [ -n "$NAMD_SMP" ]; then
CHARM_ARCH=mpi-linux-x86_64-gfortran-smp-gcc
else
CHARM_ARCH=mpi-linux-x86_64-gfortran-gcc
fi

function create_modulefile {
mkdir -p ${MODULE_DIR}
cat << EOF >> ${MODULE_DIR}/${MODULE_NAME}
#%Module
set              namdversion        ${APP_VERSION}
set              NAMDROOT           ${APP_DIR}/NAMD_\${namdversion}_Source/$NAMD_ARCH
setenv           NAMDROOT           ${APP_DIR}/NAMD_\${namdversion}_Source/$NAMD_ARCH

append-path      PATH              \$NAMDROOT
EOF
}

function build_fftw_2.1.5 {
FFTW2_TAR_GZ=fftw-2.1.5.tar.gz
wget -O $FFTW2_TAR_GZ http://www.fftw.org/$FFTW2_TAR_GZ
tar xvf $FFTW2_TAR_GZ
cd fftw-2.1.5
./configure --prefix=${APP_DIR}/fftw-2.1.5 --enable-float --enable-type-prefix
make -j 8 2>&1 | tee make.log_$$
make install 2>&1 | tee make_install.log_$$
cd ..
}

spack install gcc@7.4.0%gcc@4.8.5
source ${SPACK_ROOT}/share/spack/setup-env.sh
spack load gcc@7.4.0
spack compiler add
spack install tcl@8.5.19%gcc@7.4.0

source ${SPACK_ROOT}/share/spack/setup-env.sh

mkdir -p ${APP_DIR}
cd ${APP_DIR}

module load mpi/openmpi-4.0.2
module unload gcc-9.2.0
spack load gcc@7.4.0

build_fftw_2.1.5

cp ${NAMD_SOURCE_TAR_GZ_LOC}/${NAMD_SOURCE_NAME}.tar.gz .
tar xvf ${NAMD_SOURCE_NAME}.tar.gz

spack load tcl@8.5.19%gcc@7.4.0

OPENMPI_DIR=$(spack location -i openmpi@4.0.2%gcc@7.4.0)

cd ${NAMD_SOURCE_NAME}
tar xvf charm-6.8.2.tar
cd charm-6.8.2
./build charm++ mpi-linux-x86_64 gcc gfortran $NAMD_SMP -j16 --build-shared --basedir=/opt/openmpi-4.0.2 --with-production 2>&1 | tee build.log_$$

FFTW2_DIR=${APP_DIR}/fftw-2.1.5
TCL_DIR=$(spack location -i tcl@8.5.19%gcc@7.4.0)

cd ..
sed -i -e "s#FFTDIR=.*#FFTDIR=$FFTW2_DIR#" arch/Linux-x86_64.fftw
sed -i -e "s#^TCLDIR=.*#TCLDIR=$TCL_DIR#" arch/Linux-x86_64.tcl

./config  Linux-x86_64-g++  --charm-arch  $CHARM_ARCH $NAMD_MEMOPT 2>&1 | tee config.log_$$
cd Linux-x86_64-g++
make -j 16 2>&1 | tee make.log_$$

create_modulefile
