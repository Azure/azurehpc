#!/bin/bash
#
# Relevant environmental variables
#
# SKU_TYPE = hb, hc or hbv2 (default hbv2)
# NAMD_SOURCE_TAR_GZ_LOC, location of NAMD_2.14_Source.tar.gz source code (default hpcuser home dir)
# NAMD_SMP, set to "smp" if you want to build the smp version (default build non smp version)
# NAMD_MEMOPT, set to "--with-memopt" if you want to build memopt enabled version (default : memopt is disabled) 
#
#
APP_NAME=NAMD
APP_VERSION=2.14
CHARM_VERSION=6.10.2
SHARED_APP=/apps
NAMD_ARCH=Linux-x86_64-g++
SKU_TYPE=${SKU_TYPE:-hbv2}
MODULE_DIR=${SHARED_APP}/modulefiles/${SKU_TYPE}/${APP_NAME}
APP_TYPE=openmpi
MODULE_NAME=${APP_VERSION}-${APP_TYPE}
APP_DIR=$SHARED_APP/${SKU_TYPE}/${APP_NAME}-${APP_TYPE}
NAMD_SOURCE_NAME=${APP_NAME}_${APP_VERSION}_Source

NAMD_SOURCE_TAR_GZ_LOC=${NAMD_SOURCE_TAR_GZ_LOC:-~hpcuser}

if [ -n "$NAMD_SMP" ]; then
CHARM_ARCH=mpi-linux-x86_64-gfortran-smp-gcc
else
CHARM_ARCH=mpi-linux-x86_64-gfortran-gcc
fi

if [ $SKU_TYPE == "hbv2" ]; then
   TARGET_ARCH=zen2
else
   TARGET_ARCH=x86_64
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

spack install fftw precision=float %gcc@9.2.0 target=$TARGET_ARCH
spack install tcl@8.5.19%gcc@9.2.0

source ${SPACK_ROOT}/share/spack/setup-env.sh

mkdir -p ${APP_DIR}
cd ${APP_DIR}

module load mpi/openmpi
spack load fftw@3 target=zen2
spack load tcl@8.5.19%gcc@9.2.0

cp ${NAMD_SOURCE_TAR_GZ_LOC}/${NAMD_SOURCE_NAME}.tar.gz .
tar xvf ${NAMD_SOURCE_NAME}.tar.gz

cd ${NAMD_SOURCE_NAME}
tar xvf charm-${CHARM_VERSION}.tar
cd charm-${CHARM_VERSION}
./build charm++ mpi-linux-x86_64 gcc gfortran $NAMD_SMP -j16 --build-shared --basedir=$MPI_HOME --with-production 2>&1 | tee build.log_$$

FFTW3_DIR=$(spack location -i fftw%gcc@9.2.0)
TCL_DIR=$(spack location -i tcl@8.5.19%gcc@9.2.0)

cd ..
sed -i -e "s#FFTDIR=.*#FFTDIR=$FFTW3_DIR#" arch/Linux-x86_64.fftw
sed -i -e "s#^TCLDIR=.*#TCLDIR=$TCL_DIR#" arch/Linux-x86_64.tcl

./config  Linux-x86_64-g++  --charm-arch $CHARM_ARCH --with-fftw3 $NAMD_MEMOPT 2>&1 | tee config.log_$$
cd Linux-x86_64-g++
make -j 16 2>&1 | tee make.log_$$

create_modulefile
