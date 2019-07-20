#!/bin/bash
ZIP_FILE=ParaView-5.6.1-Windows-msvc2015-64bit.zip
VERSION=v5.6
cd /tmp

apps_dir=/apps
if [ ! -d "$apps_dir" ]; then
    apps_dir=/share/apps
fi

install_dir=$apps_dir/paraview
mkdir -p $install_dir

echo "Ready to download the install file"
wget -O $ZIP_FILE https://www.paraview.org/files/${VERSION}/${ZIP_FILE}

echo "Ready to install"
unzip -d $install_dir ParaView-5.6.1-Windows-msvc2015-64bit.zip

echo "Remove the install file"
rm -f /tmp/ParaView-5.6.1-Windows-msvc2015-64bit.zip
