#!/bin/bash
set -e

DOWNLOAD_DIR=/mnt/resource
INSTALL_DIR=/apps/ansys_inc
PACKAGE=$1
WEB_URL=$2

echo "Package: $PACKAGE"
echo "Web URL: $WEB_URL"

mkdir -p $INSTALL_DIR
cd $DOWNLOAD_DIR
pwd

echo "wget \"$WEB_URL\" -O ${PACKAGE}"
wget "$WEB_URL" -O ${PACKAGE}
echo "Untar $PACKAGE"
tar -xvf ${PACKAGE}

echo "Installing Package Dependencies"
sudo yum groupinstall -y "Server with GUI" || true
sudo yum -y install freetype motif.x86_64 mesa-libGLU-9.0.0-4.el7.x86_64

./INSTALL -silent -install_dir "$INSTALL_DIR/" -mechapdl -nohelp
