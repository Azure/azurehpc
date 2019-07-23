#!/bin/bash

module load gcc-8.2.0
source /opt/intel/impi/2018.4.274/bin64/mpivars.sh
sudo yum install -y git automake
cd /lustre
git clone https://github.com/LLNL/ior.git
cd ior
./bootstrap
MPICC=$(which mpicc) CFLAGS="-I $I_MPI_ROOT/include64" LDFLAGS="-L $I_MPI_ROOT/lib64 -lmpi" ./configure
make
cp src/ior /lustre/ior.exe
