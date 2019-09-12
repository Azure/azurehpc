#!/bin/bash
source "$azhpc_dir/libexec/common.sh"

resource_group=$1
vmname=$2
key_vault=$3
spn_appname=$4
projectstore=$5

admin_user=hpcadmin
ssh_private_key=${admin_user}_id_rsa

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
    password=$(date +%s | sha256sum | base64 | head -c 16 ; echo)
    echo "Store password in Key Vault $key_vault secret CycleAdminPassword"
    az keyvault secret set --vault-name $key_vault --name "CycleAdminPassword" --value $password --output table
fi

secret=$(az keyvault secret show --name $spn_appname --vault-name $key_vault -o json | jq -r '.value')
appId=$(echo $spn | cut -d' ' -f2)
tenantId=$(echo $spn | cut -d' ' -f3)

scp $SSH_ARGS -q -i $ssh_private_key $azhpc_dir/scripts/cyclecloud_install.sh $admin_user@$fqdn:.
ssh $SSH_ARGS -q -i $ssh_private_key $admin_user@$fqdn "sudo ./cyclecloud_install.sh $secret $appId $tenantId hpcadmin $fqdn $projectstore $password"

