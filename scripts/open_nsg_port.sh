#!/bin/bash
resource_group=$1
vmname=$2
port=$3

# Create the NSG to open port 443
echo "Open port $port for $vmname"
az network nsg rule create \
    -g ${resource_group} \
    --nsg-name ${vmname}_nsg \
    --name cyclehttps \
    --priority 2000 \
    --protocol Tcp \
    --destination-port-ranges ${port} \
    --output table
