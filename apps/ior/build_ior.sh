#!/bin/bash
APP_NAME=ior
SHARED_APP=${SHARED_APP:-/apps}
MODULE_DIR=${SHARED_APP}/modulefiles
MODULE_NAME=${APP_NAME}
INSTALL_DIR=${SHARED_APP}/${APP_NAME}
PARALLEL_BUILD=8
IOR_VERSION=3.2.1

sudo yum install -y jq

source /etc/profile.d/modules.sh # so we can load modules
# GCC 8 is no longer provided with CentOS-HPC 7.7 image, it is now 9.2, but is this really needed ?
module load gcc-9.2.0

AZHPC_VMSIZE=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2018-10-01" | jq -r '.compute.vmSize')
export AZHPC_VMSIZE=${AZHPC_VMSIZE,,}
echo "Running on $AZHPC_VMSIZE"
if [ "$AZHPC_VMSIZE" = "" ]; then
    echo "unable to retrieve VM Size - Exiting"
    exit 1
fi

case "$AZHPC_VMSIZE" in
    standard_hb60rs | standard_hc44rs | standard_hb120rs_v2 )
        module load mpi/hpcx
        ;;
    *)
        sudo yum install -y mpich-3.2-devel
        module load mpi/mpich-3.2-x86_64
        ;;
esac

module list
function create_modulefile {
mkdir -p ${MODULE_DIR}
cat << EOF > ${MODULE_DIR}/${MODULE_NAME}
#%Module
prepend-path PATH ${INSTALL_DIR}/bin;
prepend-path LD_LIBRARY_PATH ${INSTALL_DIR}/lib;
prepend-path MAN_PATH ${INSTALL_DIR}/share/man;
EOF
}

cd $SHARED_APP
IOR_PACKAGE=ior-$IOR_VERSION.tar.gz
wget https://github.com/hpc/ior/releases/download/$IOR_VERSION/$IOR_PACKAGE
tar xvf $IOR_PACKAGE
rm $IOR_PACKAGE

cd ior-$IOR_VERSION

CC=`which mpicc`
./configure --prefix=${INSTALL_DIR}
make -j ${PARALLEL_BUILD}
make install

create_modulefile
