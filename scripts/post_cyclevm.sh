#!/bin/bash
resource_group=$1
key_vault=$2
spn_appname=$3

# Create Key Vault to store secrets and keys
az keyvault show -n $key_vault --output table 2>/dev/null
if [ "$?" = "0" ]; then
    echo "keyvault $key_vault already exists"
else
    az keyvault create --name $key_vault --resource-group $resource_group --output table
fi

# Check if we need to create a new SPN
# If the SPN doesn't exists, create one and store the password in KeyVault. Secret name is the SPN app Name
spn=$(az ad sp list --show-mine --output tsv --query "[?displayName=='$spn_appname'].[displayName,appId,appOwnerTenantId]")

if [ "$spn" == "" ]; then
    echo "Generate a new SPN"
    secret=$(az ad sp create-for-rbac --name $spn_appname --years 1 | jq -r '.password')
    echo "Store secret in Key Vault $key_vault under secret name $spn_appname"
    az keyvault secret set --vault-name $key_vault --name "$spn_appname" --value $secret --output table
    spn=$(az ad sp list --show-mine --output tsv --query "[?displayName=='$spn_appname'].[displayName,appId,appOwnerTenantId]")
fi
