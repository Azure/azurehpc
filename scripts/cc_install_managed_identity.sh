#!/bin/bash
fqdn=$1
admin_user=$2
password=$3
projectstore=$4
cc_version=${5-8}

case "$cc_version" in
    7)
        PYTHON=python
        ;;
    8)
        PYTHON=python3
        # if ! rpm -q python3; then
        #     yum install -y python3
        # fi
        ;;
    *)
        echo "Version $cc_version not supported"
        exit 1
        ;;
esac

key=$(cat /home/$admin_user/.ssh/id_rsa.pub)

# Retrieve the Azure Cloud environemnt from the metadata
AZHPC_AZURE_ENVIRONMENT=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2019-08-15" | jq -r '.azEnvironment' | tr '[:upper:]' '[:lower:]')
case "$AZHPC_AZURE_ENVIRONMENT" in
    azurepubliccloud)
        azure_environment="public"
        ;;
    azureusgovernmentcloud)
        azure_environment="usgov"
        ;;
    *)
        echo "Unsupported Azure Cloud Environment"
        exit 1
        ;;
esac

echo "Setup cyclecloud_config.py for $fqdn"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
$PYTHON $DIR/cyclecloud${cc_version}_config.py \
    --useManagedIdentity \
    --username $admin_user \
    --hostname $fqdn \
    --acceptTerms  \
    --publickey "$key" \
    --password ${password} \
    --azureSovereignCloud $azure_environment \
    --storageAccount $projectstore || exit 1

echo "CycleCloud application server installation finished"
echo "Navigate to https://$fqdn and login using $admin_user"

