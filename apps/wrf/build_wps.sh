#!/bin/bash
MPI_TYPE=${1:-$openmpi}
SKU_TYPE=${2:-$hbv2}
APP_NAME=wps
APP_VERSION=4.1
SHARED_APP=${SHARED_APP:-/apps}
MODULE_DIR=${SHARED_APP}/modulefiles/${SKU_TYPE}/${APP_NAME}
APPS_WRF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MODULE_NAME=${APP_VERSION}-${MPI_TYPE}
APP_DIR=$SHARED_APP/${SKU_TYPE}/${APP_NAME}-${MPI_TYPE}

function create_modulefile {
mkdir -p ${MODULE_DIR}
cat << EOF >> ${MODULE_DIR}/${MODULE_NAME}
#%Module
set              wpsversion        ${APP_VERSION}
set              WPSROOT           ${APP_DIR}/WPS-\$wpsversion
setenv           WPSROOT           ${APP_DIR}/WPS-\$wpsversion

append-path      PATH              \$WPSROOT
EOF
}

function get_version {
    # TODO : get these versions dynamically from the image
    GCC_VERSION=9.2.0
    WRF_VERSION=4.1.5
    case $MPI_TYPE in
        openmpi)
            MPI_VER=5.0.2
        ;;
        mvapich2)
            MPI_VER=2.3.5
        ;;
    esac
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

function get_wps {
    echo "get WPS source"
    mkdir -p ${APP_DIR}
    cd ${APP_DIR}

    if [ ! -e v${APP_VERSION}.tar.gz ]; then
        wget -q https://github.com/wrf-model/WPS/archive/v${APP_VERSION}.tar.gz
        tar xf v${APP_VERSION}.tar.gz
    fi
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

function get_wrf_conf {
    export HDF5=$(spack location -i hdf5^${MPI_TYPE})
    echo "HDF5=$HDF5"
    export NETCDF=$(spack location -i netcdf-fortran^${MPI_TYPE})
    echo "NETCDF=$NETCDF"
    export WRF_DIR=${SHARED_APP}/${SKU_TYPE}/wrf-${MPI_TYPE}/WRF-${WRF_VERSION}
    echo "WRF_DIR=$WRF_DIR"
    export MPI_LIB=""
}

install_packages
get_version
load_spack
get_wps
spack_load
get_wrf_conf

cd WPS-${APP_VERSION}
./configure << EOF
3
EOF

./compile || exit 1

create_modulefile
