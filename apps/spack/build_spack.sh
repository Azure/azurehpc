#!/bin/bash
APPS_SPACK_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_NAME=spack
APP_VERSION=0.15.4
SHARED_APP=${SHARED_APP:-/apps}
INTEL_MPI_VERSION=${INTEL_MPI_VERSION:-2020.1.217}

MODULE_DIR=${SHARED_APP}/modulefiles/${APP_NAME}
MODULE_NAME=${APP_NAME}_${APP_VERSION}

SKU_TYPE=$1
email_address=$2
STORAGE_ENDPOINT=$3

if [ -z "$SKU_TYPE" ]; then
    echo "SKU_TYPE parameter is required"
    exit 1
fi

CONFIG_YAML=config.yaml
PACKAGES_YAML=packages.yaml

function create_modulefile {
    mkdir -p ${MODULE_DIR}
    cat << EOF >> ${MODULE_DIR}/${MODULE_NAME}
#%Module 1.0
#
#  Spack module for use with 'environment-modules' package:
#
setenv    SPACK_HOME        ${SPACKDIR}
setenv    SPACK_SETUP_ENV   ${SPACKDIR}/spack/share/spack/setup-env.sh
EOF

    # Create an symlink for the unversioned module name
    ln -s ${MODULE_DIR}/${MODULE_NAME} ${MODULE_DIR}/${APP_NAME}
}

sudo yum install -y python3 patch

SPACKDIR=${SHARED_APP}/${APP_NAME}/${APP_VERSION}
mkdir -p $SPACKDIR
cd $SPACKDIR
git clone https://github.com/spack/spack.git
cd spack
git checkout tags/v${APP_VERSION}

cp -r ${APPS_SPACK_DIR}/var  ${SPACKDIR}/spack
cp -r ${APPS_SPACK_DIR}/lib  ${SPACKDIR}/spack

create_modulefile
module use ${SHARED_APP}/modulefiles
module load spack/spack
source $SPACK_SETUP_ENV

mkdir -p ${SHARED_APP}/spack/${SKU_TYPE}

sed -i "s/SKU_TYPE/${SKU_TYPE}/" ${APPS_SPACK_DIR}/${CONFIG_YAML}
sed -i "s#SHARED_APP#${SHARED_APP}#" ${APPS_SPACK_DIR}/${CONFIG_YAML}
sed -i "s/INTEL_MPI_VERSION/${INTEL_MPI_VERSION}/g" ${APPS_SPACK_DIR}/${PACKAGES_YAML}

mkdir ~/.spack
cp ${APPS_SPACK_DIR}/${CONFIG_YAML} ~/.spack
cp ${APPS_SPACK_DIR}/packages.yaml ~/.spack
cp ${APPS_SPACK_DIR}/compilers.yaml ~/.spack

if [ ! -z $email_address ] && [ ! -z $STORAGE_ENDPOINT ]; then
    pip3 install --user azure-storage-blob
    spack gpg init
    spack gpg create ${SKU_TYPE}_gpg $email_address
    AZURE_STORAGE=$(echo $STORAGE_ENDPOINT | sed 's/https/azure/')
    spack mirror add ${SKU_TYPE}_buildcache ${AZURE_STORAGE}buildcache/${SKU_TYPE}
fi

cd $SPACKDIR
patch -t -p0 < ${APPS_SPACK_DIR}/web_azure.patch
patch -t -p0 < ${APPS_SPACK_DIR}/fetch_strategy_azure.patch
patch -t -p0 < ${APPS_SPACK_DIR}/darshan-runtime_package.patch

