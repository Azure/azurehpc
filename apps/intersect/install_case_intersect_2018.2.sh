#!/bin/bash
#
#Set environmental variable DATA_TGZ_SAS_URL
#DATA_TGZ_SAS_URL=/url_path/to/casedata.tgz

if [[ $IX_DATA_TGZ_SAS_URL =~ .*\/(.+)\? ]]; then
   IX_DATA_TGZ=${BASH_REMATCH[1]}
fi

IX_DATA_INSTALL_DIR=${IX_DATA_INSTALL_DIR:-/data}

pushd $IX_DATA_INSTALL_DIR
if [ ! -f ${IX_DATA_INSTALL_DIR}/${IX_DATA_TGZ} ]; then
wget -O ${IX_DATA_TGZ} "$IX_DATA_TGZ_SAS_URL"
fi
popd
