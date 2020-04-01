#!/bin/bash

NAME=$1
INSTANCES=$2
SKU=$3

case $SKU in
  Standard_D4s_v3) 
    echo "NodeName=${NAME}[0001-$(printf "%04d" ${INSTANCES})] CPUs=4 Boards=1 SocketsPerBoard=1 CoresPerSocket=2 ThreadsPerCore=2 RealMemory=16028 State=CLOUD" >> /apps/slurm/partition.conf
    ;;
  Standard_E4s_v3) 
    echo "NodeName=${NAME}[0001-$(printf "%04d" ${INSTANCES})] CPUs=4 Boards=1 SocketsPerBoard=1 CoresPerSocket=2 ThreadsPerCore=2 RealMemory=32156 State=CLOUD" >> /apps/slurm/partition.conf
    ;;
  Standard_HB60rs)
    echo "NodeName=${NAME}[0001-$(printf "%04d" ${INSTANCES})] CPUs=60 Boards=1 SocketsPerBoard=15 CoresPerSocket=4 ThreadsPerCore=1 RealMemory=229728 State=CLOUD" >> /apps/slurm/partition.conf
    ;;
  *)
    echo "NodeName=${NAME}[0001-$(printf "%04d" ${INSTANCES})] CPUs=1 RealMemory=1024 State=CLOUD" >> /apps/slurm/partition.conf
    ;;
esac

echo "PartitionName=${NAME} Nodes=${NAME}[0001-$(printf "%04d" ${INSTANCES})] Default=YES MaxTime=INFINITE State=UP" >> /apps/slurm/partition.conf

systemctl restart slurmctld
