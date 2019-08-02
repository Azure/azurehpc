#!/bin/bash

DATA_TAR_SAS_URL=/path/to/casedata.tar
DATA_TAR=BO_192_192_28.tgz

SHARED_DATA=/data

pushd $SHARED_DATA
if [ ! -f ${SHARED_DATA}/${DATA_TAR} ]; then
wget -O ${DATA_TAR} "$DATA_TAR_SAS_URL"
fi
popd
