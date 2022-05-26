#!/bin/bash
  
module load mpi/hpcx

NP=$1
HOSTFILE=$2
BASE_DIR=/opt
NCCL_TESTS_EXE=all_reduce_perf


mpirun -np $NP -hostfile $HOSTFILE --bind-to numa --map-by ppr:8:node -x CUDA_VISIBLE_DEVICES="2,1,7,5,3,0,6,4" -x LD_LIBRARY_PATH=/usr/local/nccl-rdma-sharp-plugins/lib:$LD_LIBRARY_PATH -x NCCL_DEBUG=INFO -mca coll_hcoll_enable 0 -x NCCL_IB_PCI_RELAXED_ORDERING=1 -x UCX_TLS=tcp -x UCX_NET_DEVICES=eth0 -x CUDA_DEVICE_ORDER=PCI_BUS_ID -x NCCL_SOCKET_IFNAME=eth0 -x NCCL_TOPO_FILE=/opt/microsoft/ndv4-topo.xml ${BASE_DIR}/nccl-tests/build/$NCCL_TESTS_EXE -b8 -f 2 -g 1 -e 8G -c 1
