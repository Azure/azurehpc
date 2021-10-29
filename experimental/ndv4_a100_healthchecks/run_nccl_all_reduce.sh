#!/bin/bash

module load mpi/hpcx

which mpirun

HOST1=$1
HOST2=$2

EXE_DIR=/opt/nccl-tests/build

export CUDA_VISIBLE_DEVICES=2,3,0,1,6,7,4,5
mpirun -np 16 -host ${HOST1},${HOST2} --oversubscribe --map-by ppr:2:numa -x LD_LIBRARY_PATH=/opt/hpcx-v2.8.3-gcc-MLNX_OFED_LINUX-5.2-2.2.3.0-ubuntu18.04-x86_64/nccl_rdma_sharp_plugin/lib:$LIBRARY_PATH -x NCCL_DEBUG=info -mca coll_hcoll_enable 0 -x NCCL_IB_PCI_RELAXED_ORDERING=1 -x NCCL_SOCKET_IFNAME=eth0 -x NCCL_TOPO_FILE=/opt/microsoft/ndv4-topo.xml ${EXE_DIR}/all_reduce_perf -b 4G -f 2 -g 1 -e 8G
