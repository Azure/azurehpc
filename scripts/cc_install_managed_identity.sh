#!/bin/bash
fqdn=$1
admin_user=$2
password=$3
projectstore=$4

echo "Get cyclecloud_install.py"
wget -q "https://raw.githubusercontent.com/dapolloxp/AzureCycleAKSDeployment/master/docker/cyclecloud7/scripts/cyclecloud_install.py"

key=$(cat /home/$admin_user/.ssh/id_rsa.pub)

echo "Setup cyclecloud_install.py for $fqdn"
python cyclecloud_install.py \
    --useManagedIdentity \
    --username $admin_user \
    --hostname $fqdn \
    --acceptTerms  \
    --publickey "$key" \
    --password ${password} \
    --storageAccount $projectstore
if [ "$?" -ne "0" ]; then
    echo "Error : Error installing Cycle Cloud"
    exit 1
fi

echo "CycleCloud application server installation finished"
echo "Navigate to https://$fqdn and login using $admin_user"
