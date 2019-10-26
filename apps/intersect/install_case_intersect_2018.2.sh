#!/bin/bash

DATA_TAR_SAS_URL=/path/to/casedata.tar.tgz
DATA_TAR=BO_192_192_28.tgz

DATA_INSTALL_DIR=${DATA_INSTALL_DIR:-/data}

pushd $DATA_INSTALL_DIR
if [ ! -f ${DATA_INSTALL_DIR}/${DATA_TAR} ]; then
wget -O ${DATA_TAR} "$DATA_TAR_SAS_URL"
fi
popd
