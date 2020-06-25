#!/bin/bash
fqdn=$1
admin_user=$2
password=$3
projectstore=$4
cc_version=${5-7}

case "$cc_version" in
    7)
        PYTHON=python
        ;;
    8)
        PYTHON=python3
        if ! rpm -q python3; then
            yum install -y python3
        fi
        ;;
    *)
        echo "Version $cc_version not supported"
        exit 1
        ;;
esac

echo "Get cyclecloud_install.py"
wget -q "https://raw.githubusercontent.com/dapolloxp/AzureCycleAKSDeployment/master/docker/cyclecloud${cc_version}/scripts/cyclecloud_install.py"

key=$(cat /home/$admin_user/.ssh/id_rsa.pub)

echo "Setup cyclecloud_install.py for $fqdn"
$PYTHON cyclecloud_install.py \
    --useManagedIdentity \
    --username $admin_user \
    --hostname $fqdn \
    --acceptTerms  \
    --publickey "$key" \
    --password ${password} \
    --storageAccount $projectstore
if [ $? -ne 0 ]; then
    echo "Error : Error installing Cycle Cloud"
    exit 1
fi

echo "CycleCloud application server installation finished"
echo "Navigate to https://$fqdn and login using $admin_user"

