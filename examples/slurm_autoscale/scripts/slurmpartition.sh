#!/bin/bash

config_path=/apps/slurm/azscale/config.json
sku_lookup=scripts/skus.lst

# Initialize Azure CLI
az login --identity -o table

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

  # Azure CLI is not reporting accurate values for the SKU memory
  # Temporarily rely on lookup table until Azure CLI is fixed
  RealMemory=$(awk "/$sku/"'{print $2}' $sku_lookup)
  if [[ -z "$RealMemory" ]]; then
    echo "ERROR: Cannot find $sku in memory lookup table ($sku_lookup)"
    exit 1
  fi

  #RealMemory=$(echo $vm_capabilities | jq -r '.[] | select(.name=="MemoryGB") | .value')
  ## MemoryGB can be a floating value
  #RealMemory=$(bc <<< "(${RealMemory} * 1024) / 1")
  
  # Reserve 5% of VM memory for system up to max 5 GB
  MemSpecLimit=$(bc <<< "( ${RealMemory} * 0.05 / 1)")
  if [ $MemSpecLimit -gt 5120 ]; then
    MemSpecLimit=5120
  fi

  numcores=$(echo $vm_capabilities | jq -r '.[] | select(.name=="vCPUs") | .value')

  ThreadsPerCore=$(echo $vm_capabilities | jq -r '.[] | select(.name=="vCPUsPerCore") | .value')
  if [[ "$ThreadsPerCore" == "" ]]; then 
    ThreadsPerCore=1
  fi

  # Get number of sockets (NUMA nodes) from lookup table
  Sockets=$(awk "/$sku/"'{print $3}' $sku_lookup)
  
  CoresPerSocket=$(( numcores / (Sockets * ThreadsPerCore) ))

  # If hyperthreading is enabled in the SKU, allocate only physical cores
  # by setting the number of CPUs per node as the number of physical cores
  if [[ "$ThreadsPerCore" != 1 ]]; then
    CPUs=$(( numcores / ThreadsPerCore ))
  else
    CPUs=$numcores
  fi

  # Remove "Standard_" from the SKU name to use as node feature
  NodeFeature=$(echo $sku | cut -f2,3 -d'_')

  # Calculate max nodes index
  idx_end=$(printf "%04d" ${instances})
  
  echo "NodeName=${partition}-[0001-$idx_end] CPUs=$CPUs Sockets=$Sockets CoresPerSocket=$CoresPerSocket ThreadsPerCore=$ThreadsPerCore RealMemory=$RealMemory MemSpecLimit=$MemSpecLimit Feature=$NodeFeature State=CLOUD" >> /apps/slurm/nodes.conf
  echo "PartitionName=${partition} Nodes=${partition}-[0001-$idx_end] Default=NO OverSubscribe=YES DefMemPerCPU=10240 MaxTime=INFINITE State=UP" >> /apps/slurm/partitions.conf
  
done

systemctl restart slurmctld
