#!/bin/bash
rg=$1
vm_name=$2
image_name=$3
hyperv=${4-v1}

# Create the Image
echo "Deallocate $vm_name"
az vm deallocate -g $rg -n $vm_name
echo "Generalize $vm_name"
az vm generalize -g $rg -n $vm_name
echo "Create Image $image_name from VM $vm_name"
az image create -g $rg -n $image_name --source $vm_name --hyper-v-generation $hyperv --output table

# Delete the VM
disk=$(az vm show -n $vm_name -g $rg --query "[storageProfile.osDisk.name]" -o tsv)
echo "Delete VM $vm_name"
az vm delete -g $rg -n $vm_name --yes

# Delete NIC
echo "Delete NIC ${vm_name}_nic"
az network nic delete -g $rg -n ${vm_name}_nic

# Delete NSG
echo "Delete NSG ${vm_name}_nsg"
az network nsg delete -g $rg -n ${vm_name}_nsg

# Delete the DISK
echo "Delete Disk $disk"
az disk delete -g $rg -n $disk --yes

# If a public IP delete it
pip=$(az network public-ip show -n ${vm_name}_pip -g $rg)
if [ -n "$pip" ]; then
    echo "Delete Public IP ${vm_name}_pip"
    az network public-ip delete -n ${vm_name}_pip -g $rg
fi

# Get the image id
az image show -g $rg -n $image_name --query "[id]" -o tsv
