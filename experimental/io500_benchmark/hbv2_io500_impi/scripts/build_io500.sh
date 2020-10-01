#!/bin/bash

APP_NAME=io500-app
APP_VERSION=io500-isc20_v4
SHARED_APP=/apps
MODULE_DIR=${SHARED_APP}/modulefiles
MODULE_NAME=${APP_NAME}
INSTALL_DIR=${SHARED_APP}/${APP_NAME}

source /etc/profile.d/modules.sh

module load gcc-9.2.0
module load mpi/impi_2018.4.274

function create_modulefile {
mkdir -p ${MODULE_DIR}
cat << EOF >> ${MODULE_DIR}/${MODULE_NAME}
#%Module
prepend-path PATH ${INSTALL_DIR};
prepend-path PATH ${INSTALL_DIR}/bin;
prepend-path LD_LIBRARY_PATH ${INSTALL_DIR}/lib;
setenv IO500_INSTALL_BASE ${INSTALL_DIR};
EOF
}

cd ${SHARED_APP}
export CC=`which mpicc`
git clone https://github.com/VI4IO/${APP_NAME}
cd $APP_NAME
git checkout tags/$APP_VERSION

./prepare.sh
make

create_modulefile
