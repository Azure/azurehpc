#!/bin/bash
# Create a Key vault if it doesn't exists
resource_group=$1
key_vault=$2
location=$3

# Create Key Vault to store secrets and keys
az keyvault show -n $key_vault --output table 2>/dev/null
if [ "$?" = "0" ]; then
    echo "keyvault $key_vault already exists"
else
    az keyvault create --name $key_vault --resource-group $resource_group --location $location  --output table
fi
