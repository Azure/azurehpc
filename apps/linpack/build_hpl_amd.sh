#!/bin/bash
# Prerequisites : OpenMPI 4.0.x + GCC 9.x
SHARED_APP=${1:-/apps}
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
set -e
source /etc/profile
module use /usr/share/Modules/modulefiles
module load mpi/hpcx
module load gcc-9.2.0

sudo yum install -y hwloc hwloc-devel libevent-devel
#yum install -y autoconf automake 

BUILD_DIR=$SHARED_APP/linpack
export BLIS_HOME=/opt/amd/blis-mt

build_hpl() {
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

cd $BUILD_DIR

build_hpl


