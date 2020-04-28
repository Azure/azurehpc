#!/bin/bash
# Prerequisites : OpenMPI 4.0.x + GCC 9.x
SHARED_APP=${1:-/apps}
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
set -e
source /etc/profile
module use /usr/share/Modules/modulefiles

AZHPC_VMSIZE=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2018-10-01" | jq -r '.vmSize')
AZHPC_VMSIZE=${AZHPC_VMSIZE,,}

build_amd_hpl() {
    # Get HPL. Release 2.3 supports OpenMPI 4.0.x
    wget -q http://www.netlib.org/benchmark/hpl/hpl-2.3.tar.gz
    tar xf hpl-2.3.tar.gz
    pushd hpl-2.3

    export HPL_DIR=$(pwd)
    echo $HPL_DIR

    cp $DIR/Make.Linux_AMD_BLIS .
    make arch=Linux_AMD_BLIS
    popd
}

case $AZHPC_VMSIZE in
    standard_hb60rs | standard_hb120rs_v2)
        module load mpi/hpcx
        module load gcc-9.2.0

        sudo yum install -y hwloc hwloc-devel libevent-devel
        BUILD_DIR=$SHARED_APP/linpack
        mkdir -p $BUILD_DIR
        export BLIS_HOME=/opt/amd/blis-mt

        pushd $BUILD_DIR
        build_amd_hpl
        popd
    ;;
esac

