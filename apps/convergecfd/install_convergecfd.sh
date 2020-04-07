#!/bin/bash

# parameters that can be overridden
APP_INSTALL_DIR=${APP_INSTALL_DIR:-/apps}
CONVERGECFD_INSTALLER_FILE=${CONVERGECFD_INSTALLER_FILE:-/mnt/resource/Convergent_Science_Full_Package-3.0.12.tar.gz}
CONVERGECFD_VERSION=$(tmp=${CONVERGECFD_INSTALLER_FILE/*[_-]}; echo ${tmp/\.tar.gz})
CONVERGECFD_MAJOR_VERSION=${CONVERGECFD_VERSION%.*}

if [ ! -e $CONVERGECFD_INSTALLER_FILE ]; then
    echo "Error:  $CONVERGECFD_INSTALLER_FILE does not exist"
    echo "You can set the path to the file with the variable CONVERGECFD_INSTALLER_FILE"
    exit 1
fi

echo "Install ConvergeCFD"
echo "Installer: $CONVERGECFD_INSTALLER_FILE"


if [ "$CONVERGECFD_MAJOR_VERSION" == "2.4" ]; then
    INSTALL_DIR=${APP_INSTALL_DIR}/Convergent_Science/CONVERGE
    mkdir -p ${INSTALL_DIR}/${CONVERGECFD_VERSION}
    cd ${INSTALL_DIR}/${CONVERGECFD_VERSION}
    tar -xzvf ${CONVERGECFD_INSTALLER_FILE}
    
elif [ "$CONVERGECFD_MAJOR_VERSION" == "3.0" ]; then
    dir=$(dirname $CONVERGECFD_INSTALLER_FILE)
    cd $dir
    mkdir tmp_ccfd
    cd tmp_ccfd
    tar xzvf $CONVERGECFD_INSTALLER_FILE

    cd Convergent_Science_Full_Package-${CONVERGECFD_VERSION}
    ./INSTALL ${APP_INSTALL_DIR}
    cd ../..
    rm -rf tmp_ccfd
else
    echo "Unsupported version $CONVERGECFD_VERSION for the installer"
fi
