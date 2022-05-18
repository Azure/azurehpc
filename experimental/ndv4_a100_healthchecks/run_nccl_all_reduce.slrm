#!/bin/bash
#SBATCH -t 00:5:00
#SBATCH --ntasks-per-node=8
#SBATCH --cpus-per-task=12
#SBATCH --gpus-per-node=8
#SBATCH --mem=0
#SBATCH -o logs/%x_%j.log

export UCX_IB_PCI_RELAXED_ORDERING=on \
       CUDA_DEVICE_ORDER=PCI_BUS_ID \
       NCCL_DEBUG=WARN \
       NCCL_IB_PCI_RELAXED_ORDERING=1 \
       NCCL_TOPO_FILE=/opt/microsoft/ndv4-topo.xml \
       NCCL_SOCKET_IFNAME=eth0 \
       UCX_NET_DEVICES=eth0 \
       OMPI_MCA_coll_hcoll_enable=0 \
       LD_LIBRARY_PATH=/usr/local/nccl_rdma_sharp_plugins/lib:$LIBRARY_PATH

PIN_MASK='ffffff000000,ffffff000000,ffffff,ffffff,ffffff000000000000000000,ffffff000000000000000000,ffffff000000000000,ffffff000000000000'

source /etc/profile.d/modules.sh
module load mpi/hpcx

EXE_DIR=/opt/nccl-tests/build

srun --mpi=pmix --cpu-bind=mask_cpu:$PIN_MASK \
     ${BASE_DIR}/nccl-tests/build/all_reduce_perf -b 4G -f 2 -g 1 -c 1 -e 8G
