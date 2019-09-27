#!/bin/bash

# parameters that can be overridden
APP_INSTALL_DIR=${APP_INSTALL_DIR:-/apps}
TMP_DIR=${TMP_DIR:-/mnt/resource}
RADIOSS_INSTALLER_FILE=${RADIOSS_INSTALLER_FILE:-/mnt/resource/hwSolvers2018_linux64.bin}
RADIOSS_HOTFIX_FILE=${RADIOSS_HOTFIX_FILE:-/mnt/resource/hwSolvers2018.0.1_hotfix_linux64.bin}

if [ ! -e $RADIOSS_INSTALLER_FILE ]; then
    echo "Error:  $RADIOSS_INSTALLER_FILE does not exist"
    echo "You can set the path to the file with the RADIOSS_INSTALLER_FILE"
    exit 1
fi

if [ ! -e $RADIOSS_HOTFIX_FILE ]; then
    echo "Error:  $RADIOSS_HOTFIX_FILE does not exist"
    echo "You can set the path to the file with the RADIOSS_HOTFIX_FILE"
    exit 1
fi

install_dir=$APP_INSTALL_DIR/altair/2018

sudo $RADIOSS_INSTALLER_FILE -i silent -DUSER_INSTALL_DIR=$install_dir
sudo $RADIOSS_HOTFIX_FILE -i silent -DUSER_INSTALL_DIR=$install_dir/
