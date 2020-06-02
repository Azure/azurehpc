#!/bin/bash

# Setup HP RGS on a Win10 VM

resource_group=$1
node_name=$2
nfs_server=$3

echo "Applying GPU extensions..."
az vm extension set \
    --resource-group $resource_group \
    --vm-name $node_name \
    --name NvidiaGpuDriverWindows \
    --publisher Microsoft.HpcCompute \
    --version 1.2 \
    --settings '{}' \
    --output table
echo "GPU extensions applied"

echo "Calling nfsclient.ps1..."
az vm run-command invoke \
    --name $node_name  \
    --resource-group $resource_group \
    --command-id RunPowerShellScript \
    --scripts @$azhpc_dir/scripts/nfsclient.ps1 \
    --parameters nfs_server=$nfs_server \
    --output table
echo "NFS done"

