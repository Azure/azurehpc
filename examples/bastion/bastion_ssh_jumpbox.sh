#!/bin/bash
set -euo pipefail

CONFIG_FILE=${1:-config.json}

ResourceGroup=$(grep resource_group ${CONFIG_FILE} | grep -v variables | awk -F'"' '{print $4}')
User=$(grep admin_user ${CONFIG_FILE} | grep -v variables | awk -F'"' '{print $4}')
JumpboxName=bastion-jumpbox

BastionName=$(az network bastion list -g ${ResourceGroup} --query '[].name' --output tsv)
TargetResourceId=$(az vm show -g ${ResourceGroup} --name ${JumpboxName} --query 'id' --output tsv)
SshPrivateKey=${User}_id_rsa

az network bastion ssh --name $BastionName \
                       --resource-group $ResourceGroup \
                       --target-resource-id $TargetResourceId \
                       --auth-type "ssh-key" \
                       --username $User \
                       --ssh-key $SshPrivateKey
