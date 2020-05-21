#!/bin/bash

NAME=$1
INSTANCES=$2
SKU=$3
LOCATION=$4

VM_CAPABILITIES=$(az vm list-skus --location $LOCATION --size $SKU --all | jq '.[0].capabilities')

ThreadsPerCore=$(echo $VM_CAPABILITIES | jq -r '.[] | select(.name=="vCPUsPerCore") | .value')
if [ "$ThreadsPerCore" == "" ]; then
  ThreadsPerCore=1
fi

RealMemory=$(echo $VM_CAPABILITIES | jq -r '.[] | select(.name=="MemoryGB") | .value')
# MemoryGB can be a floating value
RealMemory=$(bc <<< "(${RealMemory} * 1024) / 1")

CPUs=$(echo $VM_CAPABILITIES | jq -r '.[] | select(.name=="vCPUs") | .value')
Boards=1
SocketsPerBoard=1

case $SKU in
  Standard_HB60rs)
    SocketsPerBoard=15
    ;;
  Standard_HB120rs_v2)
    SocketsPerBoard=30
    ;;
  Standard_HC44rs)
    SocketsPerBoard=2
    ;;

  # Standard_D4s_v3) 
  #   echo "NodeName=${NAME}[0001-$(printf "%04d" ${INSTANCES})] CPUs=4 Boards=1 SocketsPerBoard=1 CoresPerSocket=2 ThreadsPerCore=2 RealMemory=16028 State=CLOUD" >> /apps/slurm/partition.conf
  #   ;;
  # Standard_E4s_v3) 
  #   echo "NodeName=${NAME}[0001-$(printf "%04d" ${INSTANCES})] CPUs=4 Boards=1 SocketsPerBoard=1 CoresPerSocket=2 ThreadsPerCore=2 RealMemory=32156 State=CLOUD" >> /apps/slurm/partition.conf
  #   ;;
  # Standard_HB60rs)
  #   echo "NodeName=${NAME}[0001-$(printf "%04d" ${INSTANCES})] CPUs=60 Boards=1 SocketsPerBoard=15 CoresPerSocket=4 ThreadsPerCore=1 RealMemory=229728 State=CLOUD" >> /apps/slurm/partition.conf
  #   ;;
  # *)
  #   echo "NodeName=${NAME}[0001-$(printf "%04d" ${INSTANCES})] CPUs=1 RealMemory=1024 State=CLOUD" >> /apps/slurm/partition.conf
  #   ;;
esac
CoresPerSocket=$(( CPUs / (SocketsPerBoard*Boards*ThreadsPerCore)))
echo "NodeName=${NAME}[0001-$(printf "%04d" ${INSTANCES})] CPUs=$CPUs Boards=$Boards SocketsPerBoard=$SocketsPerBoard CoresPerSocket=$CoresPerSocket ThreadsPerCore=$ThreadsPerCore RealMemory=$RealMemory State=CLOUD" >> /apps/slurm/partition.conf

echo "PartitionName=${NAME} Nodes=${NAME}[0001-$(printf "%04d" ${INSTANCES})] Default=YES MaxTime=INFINITE State=UP" >> /apps/slurm/partition.conf

systemctl restart slurmctld
