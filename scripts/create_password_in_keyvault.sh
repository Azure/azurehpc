#!/bin/bash
# Create a new password and store it in the keyvault.
# Keyvault need to exists
# If password already exists in Keyvault, don't create a new one
key_vault=$1
secret_name=$2

# If no password is stored, create a random one
password=$(az keyvault secret show --name "$secret_name" --vault-name $key_vault -o json | jq -r '.value')
if [ "$password" == "" ]; then
    echo "No secret $secret_name retrieved from Key Vault $key_vault"
    echo "Generate a password"
    # Prefix password by a * so that the prequisites for Cycle are met (3 of : Capital Case + Lower Case + Number + Extra)
    password="*$(date +%s | sha256sum | base64 | head -c 16 ; echo)"
    echo "Store password in Key Vault $key_vault secret $secret_name"
    az keyvault secret set --vault-name $key_vault --name "$secret_name" --value "$password" --output table
fi
