#!/bin/bash

APP_NAME=spack
APP_VERSION=0.13.1
SHARED_APPS=/apps
USER=`whoami`

sku_type=$1
email_address=$2
STORAGE_ENDPOINT=$3

APPS_SPACK_DIR=`pwd`
CONFIG_YAML=config.yaml

sudo yum install -y python3

SPACKDIR=${SHARED_APPS}/${APP_NAME}/${APP_VERSION}
mkdir -p $SPACKDIR
cd $SPACKDIR
git clone https://github.com/spack/spack.git
cd spack
git checkout tags/v${APP_VERSION}

mkdir ${SPACKDIR}/spack/var/spack/repos/builtin/packages/hpcx
cp ${APPS_SPACK_DIR}/package.py  ${SPACKDIR}/spack/var/spack/repos/builtin/packages/hpcx
patch -p0 < ${APPS_SPACK_DIR}/netcdf-fortran-patch

source ${SPACKDIR}/spack/share/spack/setup-env.sh
echo "source ${SPACKDIR}/spack/share/spack/setup-env.sh" >> ~/.bash_profile
sudo mkdir /mnt/resource/spack
sudo chown $USER /mnt/resource/spack

mkdir ~/.spack
sed -i "s/SKU_TYPE/${sku_type}/" ${APPS_SPACK_DIR}/${CONFIG_YAML}
cp ${APPS_SPACK_DIR}/${CONFIG_YAML} ~/.spack
cp ${APPS_SPACK_DIR}/packages.yaml ~/.spack
cp ${APPS_SPACK_DIR}/compilers.yaml ~/.spack
mkdir -p /apps/spack/${sku_type}

spack gpg init
spack gpg create ${sku_type}_gpg $email_address
#spack mirror add ${sku_type}_buildcache ${STORAGE_ENDPOINT}/buildcache/${sku_type}
