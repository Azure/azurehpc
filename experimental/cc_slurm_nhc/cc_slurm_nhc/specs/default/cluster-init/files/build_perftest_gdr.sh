#!/bin/bash

VERSION=4.5-0.12
VERSION_HASH=ge93c538
INSTALL_DIR=/opt

apt-get install -y pciutils-dev
cd ${INSTALL_DIR}
wget https://github.com/linux-rdma/perftest/releases/download/v${VERSION}/perftest-${VERSION}.${VERSION_HASH}.tar.gz
tar xvf perftest-${VERSION}.${VERSION_HASH}.tar.gz
cd perftest-4.5
./configure CUDA_H_PATH=/usr/local/cuda/include/cuda.h
make
rm ${INSTALL_DIR}/perftest-${VERSION}.${VERSION_HASH}.tar.gz
