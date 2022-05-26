#!/bin/bash

module load mpi/hpcx

HOST1=$1
HOST2=$2

EXE_DIR=/opt/nccl-tests/build

mpirun -np 16 -host ${HOST1},${HOST2} --oversubscribe --bind-to numa --map-by ppr:8:node -x CUDA_VISIBLE_DEVICES="2,1,7,5,3,0,6,4" -x LD_LIBRARY_PATH=/usr/local/nccl_rdma_sharp_plugins/lib:$LIBRARY_PATH -x NCCL_DEBUG=info -mca coll_hcoll_enable 0 -x NCCL_IB_PCI_RELAXED_ORDERING=1 -x NCCL_SOCKET_IFNAME=eth0 -x NCCL_TOPO_FILE=/opt/microsoft/ndv4-topo.xml ${EXE_DIR}/all_reduce_perf -b 4G -f 2 -g 1 -e 8G -c 1
