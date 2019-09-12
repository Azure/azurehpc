#!/bin/bash

# parameters that can be overridden
APP_INSTALL_DIR=${APP_INSTALL_DIR:-/apps}
TMP_DIR=${TMP_DIR:-/mnt/resource}
STARCCM_INSTALLER_DIR=${STARCCM_INSTALLER_DIR:-/mnt/resource}

starccm_installer=$STARCCM_INSTALLER_DIR/STAR-CCM+14.06.004_02_linux-x86_64-2.12_gnu7.1.tar.gz

if [ -e $starccm_installer ]; then
    echo "Error:  $starccm_installer does not exist"
    echo "You can set the path to the file with the STARCCM_INSTALLER_DIR"
    echo "environment variable."
    exit 1
fi

sudo yum install -y unzip

install_dir=$APP_INSTALL_DIR/starccm
tmp_dir=$TMP_DIR/tmp-starccm

mkdir -p $tmp_dir
pushd $tmp_dir

unzip $starccm_installer
cd STAR-CCM+14.06.004_02_linux-x86_64-2.12_gnu7.1
sudo ./STAR-CCM+14.06.004_02_linux-x86_64-2.12_gnu7.1.sh -i silent -DINSTALLDIR=$install_dir

popd
rm -rf $tmp_dir
