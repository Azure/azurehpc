#!/bin/bash

APP_NAME=ior
SHARED_APP=/apps
MODULE_DIR=${SHARED_APP}/modulefiles
MODULE_NAME=${APP_NAME}
INSTALL_DIR=${SHARED_APP}/${APP_NAME}
PARALLEL_BUILD=8
IOR_GIT_TAG=3.2.1

module load gcc-8.2.0
module load mpi/mpich-3.3

function create_modulefile {
mkdir -p ${MODULE_DIR}
cat << EOF >> ${MODULE_DIR}/${MODULE_NAME}
#%Module
prepend-path PATH ${INSTALL_DIR}/bin;
prepend-path LD_LIBRARY_PATH ${INSTALL_DIR}/lib;
prepend-path MAN_PATH ${INSTALL_DIR}/share/man;
EOF
}

cd /apps
git clone https://github.com/hpc/ior.git --branch $IOR_GIT_TAG
cd ior
./bootstrap

CC=`which mpicc` ./configure --prefix=${INSTALL_DIR}
make -j ${PARALLEL_BUILD}
make install

create_modulefile
