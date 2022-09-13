#!/bin/bash
# * If only two parameters are provided it creates a new randomly generated secret in the Key Vault
# * A third parameter allows to provide a secret value string or valid path for a file containing
#   the desired secret value (e.g. SSH keys)
# * Keyvault needs to exist
# * Fail if password already exists in Key Vault
key_vault=$1
secret_name=$2
[[ $# -gt 2 ]] && new_secret=$3

# Check if the secret already exists
secret=$(az keyvault secret show --name "$secret_name" --vault-name $key_vault -o json | jq -r '.value')

if [ "$secret" == "" ]; then
    echo "No secret $secret_name retrieved from Key Vault $key_vault"

    if [ -z $new_secret ]; then
        echo "Generate a random password"
        # Prefix password by a + so that the prequisites for Cycle are met (3 of : Capital Case + Lower Case + Number + Extra)
        new_secret="+$(date +%s | sha256sum | base64 | head -c 16 ; echo)"
    fi

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
