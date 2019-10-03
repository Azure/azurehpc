BUILD_DIR=/mnt/resource/hpcx
HPCX_DIR=$(ls -atr /opt | grep hpcx | tail -n1)
HPCX_HOME=/opt/${HPCX_DIR}
SHARED_APP=/apps

mkdir -p ${BUILD_DIR}
pushd ${BUILD_DIR}

tar xfp ${HPCX_HOME}/sources/openmpi-gitclone.tar.gz
tar xfp ${HPCX_HOME}/sources/ucx-1.6.0.tar.gz

source /etc/profile # so we can load modules
module load gcc-8.2.0
gcc -v
g++ -v

pushd ucx-1.6.0
./contrib/configure-release --prefix=${SHARED_APP}/ucx
make -j 32
make install
popd

pushd openmpi-gitclone

./configure --prefix=${SHARED_APP}/hpcx-2.4.1 \
    --with-ucx=${SHARED_APP}/ucx --with-hcoll=${HPCX_HOME}/hcoll \
    --enable-mpi-cxx \
    --with-platform=contrib/platform/mellanox/optimized

make -j 32
make install

ln -s ${SHARED_APP}/hpcx-2.4.1/lib/libmpi_cxx.so.40.20.0 ${SHARED_APP}/hpcx-2.4.1/lib/libmpi_cxx.so.1
ln -s ${SHARED_APP}/hpcx-2.4.1/lib/libmpi.so ${SHARED_APP}/hpcx-2.4.1/lib/libmpi.so.12

# update module file
sed "s#\$mydir#${HPCX_HOME}#g;s#\$hpcx_dir/ompi#${SHARED_APP}/hpcx-2.4.1#g" ${HPCX_HOME}/modulefiles/hpcx-ompi > ${SHARED_APP}/modulefiles/hpcx-2.4.1
