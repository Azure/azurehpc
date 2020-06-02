#!/bin/bash

resource_group=$1
node_name=$2
ad_domain=$3
ad_server=$4
ad_admin=$5
ad_password=$6

echo "Calling ad_join.ps1..."
az vm run-command invoke \
    --name $node_name  \
    --resource-group $resource_group \
    --command-id RunPowerShellScript \
    --scripts @$azhpc_dir/scripts/ad_join.ps1 \
    --parameters ad_domain=$ad_domain ad_server=$ad_server ad_admin=$ad_admin ad_password=$ad_password \
    --output table
echo "AD join done"

