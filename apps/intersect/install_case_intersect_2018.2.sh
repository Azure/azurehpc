#!/bin/bash
#
#Set environmental variable DATA_TAR_SAS_URL
#DATA_TAR_SAS_URL=/path/to/casedata.tar.tgz

if [[ $IX_DATA_TAR_SAS_URL =~ .*\/(.+)\? ]]; then
   IX_DATA_TAR=${BASH_REMATCH[1]}
fi

IX_DATA_INSTALL_DIR=${IX_DATA_INSTALL_DIR:-/data}

pushd $IX_DATA_INSTALL_DIR
if [ ! -f ${IX_DATA_INSTALL_DIR}/${IX_DATA_TAR} ]; then
wget -O ${IX_DATA_TAR} "$IX_DATA_TAR_SAS_URL"
fi
popd
