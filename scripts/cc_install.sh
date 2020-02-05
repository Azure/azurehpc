#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SSH_ARGS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q"

resource_group=$1
vmname=$2
key_vault=$3
spn_appname=$4
projectstore=$5
appId=$6

admin_user=hpcadmin
ssh_private_key=${admin_user}_id_rsa

# Create Key Vault to store secrets and keys
az keyvault show -n $key_vault --output table 2>/dev/null
if [ "$?" = "0" ]; then
    echo "keyvault $key_vault already exists"
else
    az keyvault create --name $key_vault --resource-group $resource_group --output table
fi

# If an SPN appId is provided then consider it's associated SPN secret is already stored in the KV
if [ "$appId" != "" ]; then
    tenantId="$(az account show --output tsv --query '[tenantId]')"
else
    # Check if we need to create a new SPN
    # If the SPN doesn't exists, create one and store the password in KeyVault. Secret name is the SPN app Name
    spn=$(az ad sp show --id http://$spn_appname --query "[appId,appOwnerTenantId]" -o tsv)

    if [ "$spn" == "" ]; then
        echo "Generate a new SPN"
        secret=$(az ad sp create-for-rbac --name $spn_appname --years 1 | jq -r '.password')
        echo "Store secret in Key Vault $key_vault under secret name $spn_appname"
        az keyvault secret set --vault-name $key_vault --name "$spn_appname" --value $secret --output table
        spn=$(az ad sp show --id http://$spn_appname --query "[appId,appOwnerTenantId]" -o tsv)
    else
        echo "SPN $spn_appname exists, make sure its secret is stored in $key_vault"
        secret=$(az keyvault secret show --name $spn_appname --vault-name $key_vault -o json | jq -r '.value')
        if [ "$secret" == "" ]; then
            echo "No secret stored in $key_vault for $spn_appname, appending a new secret"
            secret=$(az ad sp credential reset --append -n $spn_appname --credential-description "azhpc" | jq -r '.password')
            echo "Store new secret in Key Vault $key_vault under secret name $spn_appname"
            az keyvault secret set --vault-name $key_vault --name "$spn_appname" --value $secret --output table
        fi
    fi
    appId=$(echo "$spn" | head -n1)
    tenantId=$(echo "$spn" | tail -n1)
fi

echo "getting FQDN for $vmname"
fqdn=$(
    az network public-ip show \
        --resource-group $resource_group \
        --name ${vmname}pip --query dnsSettings.fqdn \
        --output tsv \
        2>/dev/null \
)

# Add the NSG rule for port 443 (https) for the Cycle VM
az network nsg rule create \
    -g ${resource_group} \
    --nsg-name ${vmname}NSG \
    --name cyclehttps \
    --priority 2000 \
    --protocol Tcp \
    --destination-port-ranges 443 \
    --output table

echo "Creating storage account $projectstore for projects"
az storage account create \
    --name $projectstore \
    --sku Standard_LRS \
    --resource-group $resource_group \
    --kind StorageV2 \
    --output table

# If no password is stored, create a random one
password=$(az keyvault secret show --name "CycleAdminPassword" --vault-name $key_vault -o json | jq -r '.value')
if [ "$password" == "" ]; then
    echo "No secret CycleAdminPassword retrieved from Key Vault $key_vault"
    echo "Generate a password"
    # Prefix password by a * so that the prequisites for Cycle are met (3 of : Capital Case + Lower Case + Number + Extra)
    password="*$(date +%s | sha256sum | base64 | head -c 16 ; echo)"
    echo "Store password in Key Vault $key_vault secret CycleAdminPassword"
    az keyvault secret set --vault-name $key_vault --name "CycleAdminPassword" --value "$password" --output table
fi

secret=$(az keyvault secret show --name $spn_appname --vault-name $key_vault -o json | jq -r '.value')
if [ "$secret" == "" ]; then
    echo "no secret stored in $key_vault for $spn_appname"
    exit 1
fi

echo "Get cyclecloud_install.py"
downloadURL="https://cyclecloudarm.azureedge.net/cyclecloudrelease"
release="latest"
wget -q "$downloadURL/$release/cyclecloud_install.py" -O cyclecloud_install.py

echo "Run cyclecloud_install.py on $fqdn"
scp $SSH_ARGS -q -i $ssh_private_key cyclecloud_install.py $admin_user@$fqdn:.
ssh $SSH_ARGS -q -i $ssh_private_key $admin_user@$fqdn "sudo python cyclecloud_install.py \
    --applicationSecret ${secret} \
    --applicationId $appId \
    --tenantId $tenantId \
    --azureSovereignCloud public \
    --downloadURL $downloadURL \
    --cyclecloudVersion $release \
    --username $admin_user \
    --hostname $fqdn \
    --acceptTerms  \
    --password ${password} \
    --storageAccount $projectstore"
if [ "$?" -ne "0" ]; then
    echo "Error : Error installing Cycle Cloud"
    exit 1
fi

echo "CycleCloud application server installation finished"
echo "Navigate to https://$fqdn and login using $admin_user"
