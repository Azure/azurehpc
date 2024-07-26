#!/bin/bash
set -e
MPI_TYPE=${1:-hpcx}
SKU_TYPE=${2:-hbv2}
OMP=$3
APP_NAME=wrf
APP_VERSION=4.1.5
SHARED_APP=${SHARED_APP:-/apps}
MODULE_DIR=${SHARED_APP}/modulefiles/${SKU_TYPE}/${APP_NAME}
APPS_WRF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ "$OMP" == ""  ]; then
    MODULE_NAME=${APP_VERSION}-${MPI_TYPE}
    APP_DIR=$SHARED_APP/${SKU_TYPE}/${APP_NAME}-${MPI_TYPE}
else
    MODULE_NAME=${APP_VERSION}-$OMP-${MPI_TYPE}
    APP_DIR=$SHARED_APP/${SKU_TYPE}/${APP_NAME}-$OMP-${MPI_TYPE}
fi



function create_modulefile {
mkdir -p ${MODULE_DIR}
cat << EOF >> ${MODULE_DIR}/${MODULE_NAME}
#%Module
set              wrfversion        ${APP_VERSION}
set              WRFROOT           ${APP_DIR}/WRF-\$wrfversion
setenv           WRFROOT           ${APP_DIR}/WRF-\$wrfversion

append-path      PATH              \$WRFROOT/main
EOF
}

function get_version {
    # TODO : get these versions dynamically from the image
    GCC_VERSION=9.2.0
    case $MPI_TYPE in
        hpcx)
            MPI_VER=2.7.4
        ;;
        openmpi)
            MPI_VER=5.0.2
        ;;
        mvapich2)
            MPI_VER=2.3.5
        ;;
    esac
    if [ "$OMP" == "" ]; then
        CONFIG_VALUE=34
    else
        CONFIG_VALUE=35
    fi
}

function install_packages {
    if ! rpm -q python3; then
        sudo yum install -y python3 
    fi
    if ! rpm -q jasper-devel libpng-devel; then
        sudo yum install -y jasper-devel libpng-devel 
    fi
}

function load_spack {
    source /etc/profile.d/modules.sh
    module use ${SHARED_APP}/modulefiles
    module load spack/spack
    source $SPACK_SETUP_ENV
}

function get_wrf {
    echo "get WRF source"
    mkdir -p ${APP_DIR}
    cd ${APP_DIR}

    if [ ! -e v${APP_VERSION}.tar.gz ]; then
        wget -q https://github.com/wrf-model/WRF/archive/v${APP_VERSION}.tar.gz
        tar xf v${APP_VERSION}.tar.gz
    fi
}

function spack_install {
    echo "spack install"
    spack install  netcdf-fortran ^hdf5+fortran %gcc@${GCC_VERSION} ^${MPI_TYPE}@${MPI_VER} || exit 1
}

function spack_load {
    echo "spack load"
    spack load netcdf-fortran^${MPI_TYPE}
    spack load hdf5^${MPI_TYPE}
    spack load perl
    echo "module load"
    module load mpi/${MPI_TYPE}-${MPI_VER}
    module load gcc-${GCC_VERSION}
}

function create_links {
    export HDF5=$(spack location -i hdf5^${MPI_TYPE})
    echo "HDF5=$HDF5"
    export NETCDF=$(spack location -i netcdf-fortran^${MPI_TYPE})
    echo "NETCDF=$NETCDF"

    NETCDF_C=$(spack location -i netcdf-c^${MPI_TYPE})
    echo "NETCDF_C=$NETCDF_C"
    ln -sf $NETCDF_C/include/* $NETCDF/include/
    ln -sf $(ls -p $NETCDF_C/lib/* | grep / ) $NETCDF/lib/
    ln -sf $NETCDF_C/lib/pkgconfig/* $NETCDF/lib/pkgconfig
}

function apply_patch {
    cd WRF-${APP_VERSION}
    echo "apply patch"
    patch -t -p0 < ${APPS_WRF_DIR}/WRFV4.0-rsl-8digit.patch
}

function configure {
./configure << EOF
$CONFIG_VALUE

EOF
}


install_packages
get_version
load_spack
get_wrf
spack_install
spack_load
create_links
apply_patch
configure

./compile -j 16 em_real || exit 1

create_modulefile
