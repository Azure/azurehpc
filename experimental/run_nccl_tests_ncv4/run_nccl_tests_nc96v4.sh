#!/bin/bash

module load mpi/openmpi

NP=$1
HOSTFILE=$2

BASE_DIR=/opt
NCCL_TESTS_EXE=all_reduce_perf


mpirun -np $NP -hostfile $HOSTFILE --bind-to numa --map-by ppr:4:node -x NCCL_DEBUG=INFO -x NCCL_IB_DISABLE=1 -x NCCL_TOPO_FILE=/opt/microsoft/ncv4/topo.xml -x NCCL_GRAPH_FILE=/opt/microsoft/ncv4/graph.xml ${BASE_DIR}/nccl-tests/build/$NCCL_TESTS_EXE -b8 -f 2 -g 1 -e 8G -c 1
