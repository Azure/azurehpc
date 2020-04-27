#!/bin/bash

# parameters that can be overridden
APP_INSTALL_DIR=${APP_INSTALL_DIR:-/apps}
LSDYNA_MPP_INSTALLER_FILE=${LSDYNA_MPP_INSTALLER_FILE:-/mnt/resource/ls-dyna_mpp_s_R9_3_1_x64_centos65_ifort131_avx2_intelmpi-2018.tar.gz}
LSDYNA_HYB_INSTALLER_FILE=${LSDYNA_HYB_INSTALLER_FILE:-/mnt/resource/ls-dyna_hyb_s_R9_3_1_x64_centos65_ifort131_avx2_intelmpi-2018.tar.gz}

if [ ! -e $LSDYNA_MPP_INSTALLER_FILE ]; then
    echo "Error:  $LSDYNA_MPP_INSTALLER_FILE does not exist"
    echo "You can set the path to the file with the variable LSDYNA_MPP_INSTALLER_FILE"
    exit 1
fi

echo "Install LS-DYNA"
echo "MPP Installer: $LSDYNA_MPP_INSTALLER_FILE"
echo "HYB Installer: $LSDYNA_HYB_INSTALLER_FILE"



INSTALL_DIR=${APP_INSTALL_DIR}/LS-DYNA
mkdir -p ${INSTALL_DIR}
cd ${INSTALL_DIR}
tar -xzvf ${LSDYNA_MPP_INSTALLER_FILE}
    
if [ ! -e $LSDYNA_HYB_INSTALLER_FILE ]; then
    echo "Warning:  $LSDYNA_HYB_INSTALLER_FILE does not exist"
    echo "You can set the path to the file with the variable LSDYNA_HYB_INSTALLER_FILE"
else
    tar -xzvf ${LSDYNA_HYB_INSTALLER_FILE}
fi

