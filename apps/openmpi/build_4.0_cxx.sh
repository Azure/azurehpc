OMPI_VERSION=4.0.1
SHARED_APP=/apps
MODULE_DIR=${SHARED_APP}/modulefiles
APP_NAME=openmpi

wget https://download.open-mpi.org/release/open-mpi/v4.0/openmpi-${OMPI_VERSION}.tar.gz

tar -xvf $APP_NAME-$OMPI_VERSION.tar.gz
cd openmpi-$OMPI_VERSION

source /etc/profile # so we can load modules
module load gcc-8.2.0
gcc -v
g++ -v

HPCX_DIR=$(ls -atr /opt | grep hpcx | tail -n1)
UCX_DIR=/opt/${HPCX_DIR}/ucx
HCOLL_DIR=/opt/${HPCX_DIR}/hcoll

./configure --prefix=${SHARED_APP}/${APP_NAME}-${OMPI_VERSION} \
    --with-ucx=${UCX_DIR} --with-hcoll=${HCOLL_DIR} --enable-mpi-cxx --enable-mpirun-prefix-by-default

make -j 32
make install

# OpenMPI
mkdir -p ${MODULE_DIR}
chmod 777 ${MODULE_DIR}

cat << EOF > ${MODULE_DIR}/${APP_NAME}-${OMPI_VERSION}
#%Module 1.0
#
#  OpenMPI ${OMPI_VERSION}
#
conflict        mpi
prepend-path    PATH            ${SHARED_APP}/${APP_NAME}-${OMPI_VERSION}/bin
prepend-path    LD_LIBRARY_PATH ${SHARED_APP}/${APP_NAME}-${OMPI_VERSION}/lib
prepend-path    MANPATH         ${SHARED_APP}/${APP_NAME}-${OMPI_VERSION}/share/man
setenv          MPI_BIN         ${SHARED_APP}/${APP_NAME}-${OMPI_VERSION}/bin
setenv          MPI_INCLUDE     ${SHARED_APP}/${APP_NAME}-${OMPI_VERSION}/include
setenv          MPI_LIB         ${SHARED_APP}/${APP_NAME}-${OMPI_VERSION}/lib
setenv          MPI_MAN         ${SHARED_APP}/${APP_NAME}-${OMPI_VERSION}/share/man
setenv          MPI_HOME        ${SHARED_APP}/${APP_NAME}-${OMPI_VERSION}
EOF
