#!/bin/bash

# Setup HP RGS on a Win10 VM

resource_group=$1
node_name=$2
nfs_server=$3
storage_accnt=$4

container="apps"
lic_file="hp-rgs/trial.lic"
rgs_exe="hp-rgs/SenderSetup64.exe"


start=$(date --utc -d "-2 hours" +%Y-%m-%dT%H:%M:%SZ)
end=$(date --utc -d "+1 year" +%Y-%m-%dT%H:%M:%SZ)
echo "Creating the SAS key"
rgs_sas=$(az storage container generate-sas --account-name $storage_accnt --name $container --permissions r --output tsv --start $start --expiry $end )

#echo $rgs_sas
hp_rgs_lic_url="https://${storage_accnt}.blob.core.windows.net/${container}/${lic_file}"
hp_rgs_sw_url="https://${storage_accnt}.blob.core.windows.net/${container}/${rgs_exe}"
hp_rgs_lic_url="${hp_rgs_lic_url}?${rgs_sas}"
hp_rgs_sw_url="${hp_rgs_sw_url}?${rgs_sas}"

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

echo "Installing RGS..."
az vm run-command invoke \
    --name $node_name  \
    --resource-group $resource_group \
    --command-id RunPowerShellScript \
    --scripts @nv_win_rgs.ps1 \
    --parameters lic_url="\"$hp_rgs_lic_url\"" sw_url="\"$hp_rgs_sw_url\"" \
    --output table --debug
echo "RGS Installed"

az network nsg rule create \
    --resource-group $resource_group \
    --nsg-name ${node_name}_nsg \
    --name HP-RGS \
    --priority 310 \
    --destination-port-ranges 42966 \
    --access Allow \
    --description "Allow HP RGS" \
    --output table
