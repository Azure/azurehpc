#!/bin/bash

config_path=/apps/slurm/azscale/config.json

# Get region from config.json
location=$(jq -r '.variables.location' $config_path)

# Extract compute nodes info from config.json as <partition>:<sku>:<instnaces>
partitions_specs=$(jq -r '.resources | keys[] as $k | if (.[$k] | .type) == "slurm_partition" then "\($k):\(.[$k] | .vm_type):\(.[$k] | .instances)" else empty end' $config_path)

for partspec in $partitions_specs; do

  partition=$(echo $partspec | cut -f1 -d:)
  sku=$(echo $partspec | cut -f2 -d:)
  instances=$(echo $partspec | cut -f3 -d:)

  # Get the actual SKU name in case a variable is referenced in the node definition
  if [[ $sku == *"variables"* ]]; then
    sku=".${sku}"
    sku=$(jq -r $sku $config_path);
  fi

  # Get the actual number of instances in case a variable is referenced in the node definition
  if [[ $instances == *"variables"* ]]; then
    instances=".${instances}"
    instances=$(jq -r $instances $config_path);
  fi

  vm_capabilities=$(az vm list-skus --location $location --size $sku --all | jq '.[0].capabilities')

  ThreadsPerCore=$(echo $vm_capabilities | jq -r '.[] | select(.name=="vCPUsPerCore") | .value')
  if [[ "$ThreadsPerCore" == "" ]]; then 
    ThreadsPerCore=1
  fi

  RealMemory=$(echo $vm_capabilities | jq -r '.[] | select(.name=="MemoryGB") | .value')
  # MemoryGB can be a floating value
  RealMemory=$(bc <<< "(${RealMemory} * 1024) / 1")

  CPUs=$(echo $vm_capabilities | jq -r '.[] | select(.name=="vCPUs") | .value')
  
  Boards=1
  SocketsPerBoard=1

  # Special parameters for specific SKUs
  case $sku in
  Standard_HB60rs)
    SocketsPerBoard=15
    ;;
  Standard_HB120rs_v2)
    SocketsPerBoard=30
    ;;
  Standard_HC44rs)
    SocketsPerBoard=2
    ;;
  esac

  CoresPerSocket=$(( CPUs / (SocketsPerBoard*Boards*ThreadsPerCore) ))
  
  # Remove "Standard_" from the SKU name to use as node feature
  NodeFeature=$(echo $sku | cut -f2,3 -d'_')

  # Calculate max nodes index
  idx_end=$(printf "%04d" ${instances})
  
  echo "NodeName=${partition}[0001-$idx_end] CPUs=$CPUs Boards=$Boards SocketsPerBoard=$SocketsPerBoard CoresPerSocket=$CoresPerSocket ThreadsPerCore=$ThreadsPerCore RealMemory=$RealMemory Feature=$NodeFeature State=CLOUD" >> ./nodes.conf
  echo "PartitionName=${partition} Nodes=${partition}[0001-$idx_end] Default=NO MaxTime=INFINITE State=UP" >> ./partitions.conf
  
  done

systemctl restart slurmctld
