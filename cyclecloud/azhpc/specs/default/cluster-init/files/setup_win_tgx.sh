#!/bin/bash

# Setup HP RGS on a Win10 VM

resource_group=$1
node_name=$2
nfs_server=$3
storage_accnt=$4

container="apps"
lic_file="TGX/TGX.lic"
tgx_exe="TGX/TGX_Sender_1.10.6.577_64-bit.exe"


start=$(date --utc -d "-2 hours" +%Y-%m-%dT%H:%M:%SZ)
end=$(date --utc -d "+1 year" +%Y-%m-%dT%H:%M:%SZ)
echo "Creating the SAS key"
tgx_sas=$(az storage container generate-sas --account-name $storage_accnt --name $container --permissions r --output tsv --start $start --expiry $end )

tgx_lic_url="https://${storage_accnt}.blob.core.windows.net/${container}/${lic_file}"
tgx_sw_url="https://${storage_accnt}.blob.core.windows.net/${container}/${tgx_exe}"
tgx_lic_url="${tgx_lic_url}?${tgx_sas}"
tgx_sw_url="${tgx_sw_url}?${tgx_sas}"

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

echo "Installing TGX..."
az vm run-command invoke \
    --name $node_name  \
    --resource-group $resource_group \
    --command-id RunPowerShellScript \
    --scripts @nv_win_tgx.ps1 \
    --parameters lic_url="\"$tgx_lic_url\"" sw_url="\"$tgx_sw_url\"" \
    --output table --debug
echo "TGX Installed"

az network nsg rule create \
    --resource-group $resource_group \
    --nsg-name ${node_name}_nsg \
    --name TGX \
    --priority 310 \
    --destination-port-ranges 40001-40017 \
    --access Allow \
    --description "Allow TGX" \
    --output table
