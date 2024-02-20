#!/bin/bash
set -ex

VERSION="23.07-0.5.1.2"
TARBALL="MLNX_OFED_LINUX-$VERSION-ubuntu20.04-x86_64.tgz"
MLNX_OFED_DOWNLOAD_URL=https://content.mellanox.com/ofed/MLNX_OFED-${VERSION}/$TARBALL
MOFED_FOLDER=$(basename ${MLNX_OFED_DOWNLOAD_URL} .tgz)

/workspace/download_and_verify.sh $MLNX_OFED_DOWNLOAD_URL "923ddbd48d250b25ba50098ad8852ad6a591df3e975f3e0b9922b752181bdd12"
tar zxvf ${TARBALL}

./${MOFED_FOLDER}/mlnxofedinstall --add-kernel-support --skip-unsupported-devices-check --without-fw-update --without-ucx-cuda
#write_component_version.sh "MOFED" $VERSION

# Restarting openibd
#/etc/init.d/openibd restart
