#!/bin/bash
INSTALL_TAR=$1
TAR_SAS_URL="$2"
LICENSE_PORT_IP=$3

APP_NAME=VPS2018
DOWNLOAD_DIR=/mnt/resource
SHARED_APP=/apps

INSTALL_DIR=${SHARED_APP}/${APP_NAME}
MODULE_DIR=${SHARED_APP}/modulefiles
MODULE_NAME=${APP_NAME}


pushd ${DOWNLOAD_DIR}

if [ ! -f ${INSTALL_DIR} ]; then
    mkdir -p ${INSTALL_DIR}
    wget -q "$TAR_SAS_URL" -O ${INSTALL_TAR}
    tar xvf ${INSTALL_TAR} -C ${INSTALL_DIR}
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
