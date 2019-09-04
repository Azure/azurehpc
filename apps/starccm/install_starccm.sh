#!/bin/bash

sudo yum install -y unzip

install_dir=/apps/CFD
tmp_dir=/mnt/resource/tmp-starccm

mkdir -p $tmp_dir
pushd $tmp_dir

#NOTE!!: Update the path to the starccm install file before running the script
installer=STAR-CCM+.tar.gz
#wget "https://<storage-account>.blob.core.windows.net/apps/starccm-14/STAR-CCM%2B14.06.004_02_linux-x86_64-2.12_gnu7.1.tar.gz?<sas-key>" -O $installer

echo "Install Starccm+"
echo "Installer: $installer"

unzip $installer
cd STAR-CCM*
sudo ./STAR-CCM*.sh -i silent

sudo mkdir -p /apps/CFD
sudo mv /opt/Siemens $install_dir

popd
rm -rf $tmp_dir
