#!/bin/bash
fqdn=$1
secret=$2
appId=$3
tenantId=$4
admin_user=$5
password=$6
projectstore=$7

echo "Get cyclecloud_install.py"
downloadURL="https://cyclecloudarm.azureedge.net/cyclecloudrelease"
release="latest"
wget -q "$downloadURL/$release/cyclecloud_install.py" -O cyclecloud_install.py

echo "Setup cyclecloud_install.py for $fqdn"
python cyclecloud_install.py \
    --applicationSecret ${secret} \
    --applicationId $appId \
    --tenantId $tenantId \
    --azureSovereignCloud public \
    --username $admin_user \
    --hostname $fqdn \
    --acceptTerms  \
    --password ${password} \
    --storageAccount $projectstore
if [ "$?" -ne "0" ]; then
    echo "Error : Error installing Cycle Cloud"
    exit 1
fi

echo "CycleCloud application server installation finished"
echo "Navigate to https://$fqdn and login using $admin_user"
