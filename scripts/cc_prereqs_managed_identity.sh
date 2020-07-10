#!/bin/bash
# Create all the prerequisites needed to deploy a Cycle Cloud server
# - Key vault if it doesn't exists
# - Create a Service Principal Name if it doen't exists and store it's secret in the Key Vault
# - A storage account
# - Generate a password and store it in the Keyvault
resource_group=$1
key_vault=$2
projectstore=$3

# Create Key Vault to store secrets and keys
az keyvault show -n $key_vault --output table 2>/dev/null
if [ "$?" = "0" ]; then
    echo "keyvault $key_vault already exists"
else
    az keyvault create --name $key_vault --resource-group $resource_group --enable-soft-delete false --output table
fi

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

