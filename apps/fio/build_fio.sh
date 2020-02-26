#!/bin/bash

APP_NAME=fio
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

yum install -y zlib-devel git
cd $SHARED_APP
cd $APP_NAME
#git clone git@github.com:axboe/fio.git
git clone https://github.com/axboe/fio.git

cd fio
./configure --prefix=${INSTALL_DIR}
make -j $PARALLEL_BUILD
make install

create_modulefile
