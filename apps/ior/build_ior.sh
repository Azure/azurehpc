#!/bin/bash

sudo yum install -y mpich-devel git automake
cd /lustre
git clone https://github.com/LLNL/ior.git
cd ior
./bootstrap
MPICC=/usr/lib64/mpich/bin/mpicc ./configure
make
cp src/ior /lustre/ior.exe
