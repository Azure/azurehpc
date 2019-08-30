# Fix missing shared libraries
source /etc/profile 
module use /usr/share/Modules/modulefiles
module load mpi/openmpi-4.0.1

pushd $MPI_HOME/lib
ln -s libmpi.so libmpi_cxx.so.1
ln -s libmpi.so libmpi.so.12
ls -al
popd

module unload mpi/openmpi-4.0.1

HPCX_DIR=$(ls -atr /opt | grep hpcx | tail -n1)
module use /opt/${HPCX_DIR}/modulefiles
module load hpcx
pushd $MPI_HOME/lib
ln -s libmpi.so libmpi_cxx.so.1
ln -s libmpi.so libmpi.so.12
ls -al
popd