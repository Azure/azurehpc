#!/bin/bash

resource_group=$1
vm_name=$2
instances=$3
sshkey=$4

pwd

for i in $(seq -f "%04g" 1 $instances); do
    echo az vm run-command invoke \
        --name ${vm_name}${i} \
        --resource-group $resource_group \
        --command-id RunPowerShellScript \
        --scripts @scripts/install_sshd.ps1 \
        --parameters \"sshkey=$sshkey\"
    az vm run-command invoke \
        --name ${vm_name}${i} \
        --resource-group $resource_group \
        --command-id RunPowerShellScript \
        --scripts @scripts/install_sshd.ps1 \
        --parameters "sshkey=$sshkey" &
done

wait


