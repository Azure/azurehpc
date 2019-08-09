#!/bin/bash
set -e

DOWNLOAD_DIR=/mnt/resource
INSTALL_DIR=/apps/ansys_inc
PACKAGE=$1
WEB_URL=$2

mkdir $INSTALL_DIR
cd $DOWNLOAD_DIR

wget "$WEB_URL" -O ${PACKAGE}
tar -xvf ${PACKAGE}

echo "Installing Package Dependencies"
yum groupinstall -y "X Window System"
yum -y install freetype motif.x86_64 mesa-libGLU-9.0.0-4.el7.x86_64

./INSTALL -silent -install_dir "$INSTALL_DIR/" -mechapdl -nohelp
