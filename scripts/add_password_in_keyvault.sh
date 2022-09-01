#!/bin/bash
# Add a new password in the keyvault
# Keyvault needs to exist
# Fail if password already exists in keyvault
key_vault=$1
secret_name=$2
secret_value=$3

password=$(az keyvault secret show --name "$secret_name" --vault-name $key_vault -o json | jq -r '.value')
if [ "$password" == "" ]; then
    echo "No secret $secret_name retrieved from Key Vault $key_vault"
    echo "Store password in Key Vault $key_vault secret $secret_name"
    az keyvault secret set --vault-name $key_vault --name "$secret_name" --value "$secret_value" --output table
else
    echo "ERROR: Secret $secret_name already exists in Key Vault $key_vault"
    exit 1
fi
