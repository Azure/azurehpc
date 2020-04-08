#!/bin/bash
# Create all the prerequisites needed to deploy a Cycle Cloud server
# - Key vault if it doesn't exists
# - Create a Service Principal Name if it doen't exists and store it's secret in the Key Vault
# - A storage account
# - Generate a password and store it in the Keyvault
resource_group=$1
key_vault=$2
spn_appname=$3
projectstore=$4
appId=$5

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

