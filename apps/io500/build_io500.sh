#!/bin/bash

APP_NAME=io-500-dev
SHARED_APPS=/apps
MODULE_DIR=${SHARED_APP}/modulefiles
MODULE_NAME=${APP_NAME}
INSTALL_DIR=${SHARED_APPS}/${APP_NAME}
PARALLEL_BUILD=8

module load gcc-8.2.0
module load mpi/mpich-3.3

function create_modulefile {
mkdir -p ${MODULE_DIR}
cat << EOF >> ${MODULE_DIR}/${MODULE_NAME}
#%Module
prepend-path PATH ${INSTALL_DIR}/bin;
prepend-path LD_LIBRARY_PATH ${INSTALL_DIR}/lib;
setenv IO500_INSTALL_BASE ${INSTALL_DIR};
EOF
}

cd ${SHARED_APPS}
export CC=`which mpicc`
git clone https://github.com/VI4IO/io-500-dev
cd $APP_NAME
./utilities/prepare.sh
./io500.sh

create_modulefile
