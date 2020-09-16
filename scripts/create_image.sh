#!/bin/bash
rg=$1
vm_name=$2
image_name=$3
image_rg=$4
#hyperv=${5-v1}

# Create the Image
echo "Deallocate $vm_name"
az vm deallocate -g $rg -n $vm_name
echo "Generalize $vm_name"
az vm generalize -g $rg -n $vm_name

# Retrieve the hyperv generation of the image used to create the VM as it needs to be specified when capturing the VM
imgref=$(az vm show --name $vm_name -g $rg --query "storageProfile.imageReference")
echo $imgref
offer=$(echo $imgref | jq -r '.offer')
publisher=$(echo $imgref | jq -r '.publisher')
sku=$(echo $imgref | jq -r '.sku')
version=$(echo $imgref | jq -r '.version')
hyperv=$(az vm image show --urn $publisher:$offer:$sku:$version --query "hyperVgeneration" -o tsv)
echo "hyper-v generation is $hyperv"

echo "Create Image $image_name from VM $vm_name"
if [ "$rg" == "$image_rg" ]; then
    az image create -g $rg -n $image_name --source $vm_name --hyper-v-generation $hyperv --output table
    echo "Image $image_name created in $rg"
else
    vmid=$(az vm show --name $vm_name -g $rg --query "[id]" -o tsv)
    # If the image resource group doesn't exists, create it in the same location that the VM being captured
    if [ "$(az group exists --name $image_rg)" == "false" ]; then
        location=$(az group show --name $rg --query "[location]" -o tsv)
        az group create --name $image_rg --location $location --output table
    fi
    az image create -g $image_rg -n $image_name --source $vmid --hyper-v-generation $hyperv --output table
    echo "Image $image_name created in $image_rg"
fi

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

# If a public IP exists, delete it
pip=$(az network public-ip show -n ${vm_name}_pip -g $rg)
if [ -n "$pip" ]; then
    echo "Delete Public IP ${vm_name}_pip"
    az network public-ip delete -n ${vm_name}_pip -g $rg
fi

# Dump the image id
az image show -g $image_rg -n $image_name --query "[id]" -o tsv
