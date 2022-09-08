#!/bin/bash
# Add a new secret in the keyvault from string or file
# Keyvault needs to exist
# Fail if password already exists in keyvault
key_vault=$1
secret_name=$2
new_secret=$3

secret=$(az keyvault secret show --name "$secret_name" --vault-name $key_vault -o json | jq -r '.value')
if [ "$secret" == "" ]; then
    echo "No secret $secret_name retrieved from Key Vault $key_vault"
    if [ -f "$new_secret" ]; then
        echo "Store secret $secret_name from file $new_secret in Key Vault $key_vault"
        az keyvault secret set --vault-name $key_vault --name "$secret_name" --file "$new_secret" --output table
    else
        echo "Store secret $secret_name from string in Key Vault $key_vault"
        az keyvault secret set --vault-name $key_vault --name "$secret_name" --value "$new_secret" --output table
    fi
else
    echo "ERROR: Secret $secret_name already exists in Key Vault $key_vault"
    exit 1
fi
