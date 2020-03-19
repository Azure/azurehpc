#!/bin/bash

# parameters that can be overridden
APP_INSTALL_DIR=${APP_INSTALL_DIR:-/apps}
TMP_DIR=${TMP_DIR:-/mnt/resource}
STARCCM_INSTALLER_FILE=${STARCCM_INSTALLER_FILE:-/mnt/resource/STAR-CCM+14.06.012_01_linux-x86_64-2.12_gnu7.1.zip}

if [ ! -e $STARCCM_INSTALLER_FILE ]; then
    echo "Error:  $STARCCM_INSTALLER_FILE does not exist"
    echo "You can set the path to the file with the STARCCM_INSTALLER_FILE"
    exit 1
fi

sudo yum install -y unzip

install_dir=$APP_INSTALL_DIR/starccm
tmp_dir=$TMP_DIR/tmp-starccm

mkdir -p $tmp_dir
pushd $tmp_dir

unzip $STARCCM_INSTALLER_FILE
cd STAR-CCM+*
sudo ./STAR-CCM+*.sh -i silent -DINSTALLDIR=$install_dir

popd
rm -rf $tmp_dir
