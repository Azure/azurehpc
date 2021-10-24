#!/bin/bash

sudo apt-get install -y pciutils-dev
wget https://github.com/linux-rdma/perftest/releases/download/v4.5-0.2/perftest-4.5-0.2.gddb0705.tar.gz
tar xvf perftest-4.5-0.2.gddb0705.tar.gz
cd perftest-4.5
./configure CUDA_H_PATH=/usr/local/cuda/include/cuda.h
make
