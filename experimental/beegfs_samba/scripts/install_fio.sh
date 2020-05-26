#!/bin/bash

resource_group=$1
vm_name=$2
instances=$3

pwd

for i in $(seq -f "%04g" 1 $instances); do
    echo az vm run-command invoke \
        --name ${vm_name}${i} \
        --resource-group $resource_group \
        --command-id RunPowerShellScript \
        --scripts @scripts/install_fio.ps1
    az vm run-command invoke \
        --name ${vm_name}${i} \
        --resource-group $resource_group \
        --command-id RunPowerShellScript \
        --scripts @scripts/install_fio.ps1 &
done

wait


