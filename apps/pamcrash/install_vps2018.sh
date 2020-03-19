#!/bin/bash
TAR_SASURL="$1"
MPM_SASURL="$2"
LICENSE_PORT_IP=$3
DEST=${4-/apps}

# TODO : Extract file name from SAS URL
APP_NAME=VPS2018
DOWNLOAD_DIR=/mnt/resource
SHARED_APP=$DEST

INSTALL_DIR=${SHARED_APP}/${APP_NAME}
MODULE_DIR=${SHARED_APP}/modulefiles
MODULE_NAME=${APP_NAME}

pushd ${DOWNLOAD_DIR}

if [ ! -f ${INSTALL_DIR} ]; then
    mkdir -p ${INSTALL_DIR}
    blob=${TAR_SASURL%%\?*}
    tarfile=${blob##*/}
    echo "get $TAR_SASURL to ${tarfile}"
    wget -q "$TAR_SASURL" -O ${tarfile}
    tar xvf ${tarfile} -C ${INSTALL_DIR}

    blob=${MPM_SASURL%%\?*}
    tarfile=${blob##*/}
    echo "get $MPM_SASURL to ${tarfile}"
    wget -q "$MPM_SASURL" -O ${tarfile}
    tar -xvf ${tarfile} -C $INSTALL_DIR/pamcrash_safe/2018.01/Linux_x86_64/lib/

fi

popd

mkdir -p ${MODULE_DIR}
chmod 777 ${MODULE_DIR}

cat << EOF > ${MODULE_DIR}/${MODULE_NAME}
#%Module 1.0
#
#  VPS module for use with 'environment-modules' package:
#
setenv    PAM_LMD_LICENSE_FILE    ${LICENSE_PORT_IP}
setenv    PAMHOME                 ${INSTALL_DIR}
EOF
