#!/bin/bash

APP_NAME=fio
APP_VERSION=3.22
SHARED_APP=/apps
MODULE_DIR=${SHARED_APP}/modulefiles
MODULE_NAME=${APP_NAME}
INSTALL_DIR=${SHARED_APP}/${APP_NAME}
PARALLEL_BUILD=4

function create_modulefile {
mkdir -p ${MODULE_DIR}
mkdir -p ${INSTALL_DIR}
cat << EOF >> ${MODULE_DIR}/${MODULE_NAME}
#%Module
prepend-path PATH ${INSTALL_DIR}/bin;
prepend-path LD_LIBRARY_PATH ${INSTALL_DIR}/lib;
prepend-path MAN_PATH ${INSTALL_DIR}/man;
EOF
}

sudo yum install -y zlib-devel git
cd $SHARED_APP
git clone https://github.com/axboe/fio.git
cd fio
git checkout tags/fio-${APP_VERSION}

module load gcc-9.2.0
./configure --prefix=${INSTALL_DIR}
make -j $PARALLEL_BUILD
make install

create_modulefile
