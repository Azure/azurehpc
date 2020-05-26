#!/bin/bash

resource_group=$1
vmss_name=$2
client_name=$3
client_instances=$4

servers=($( \
    az vmss nic list \
        --resource-group $resource_group \
        --vmss-name $vmss_name \
        --query [].ipConfigurations[].privateIpAddress \
        --output tsv \
))
nservers=${#servers[@]}

for i in $(seq 1 $client_instances); do

    vm_name=${client_name}$(printf "%04d" $i)

    server_ip=${servers[$(($i % $nservers))]}

    echo "Setting $vm_name to $server_ip"

    azhpc-run -c scripts/config.json -n $vm_name 'echo \"New-PSDrive -Name Z -Root \\'$server_ip'\beegfs -Scope Global -Persist -PSProvider FileSystem\" | Set-Content -LiteralPath mount_beegfs.ps1 -Encoding Default'

done
