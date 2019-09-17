#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$azhpc_dir/libexec/common.sh"
DEBUG_ON=0
COLOR_ON=1

resource_group=$1
vmname=$2
key_vault=$3
spn_appname=$4
projectstore=$5
config=$6

admin_user=hpcadmin
ssh_private_key=${admin_user}_id_rsa

# Create Key Vault to store secrets and keys
az keyvault show -n $key_vault --output table 2>/dev/null
if [ "$?" = "0" ]; then
    status "keyvault $key_vault already exists"
else
    az keyvault create --name $key_vault --resource-group $resource_group --output table
fi

# Check if we need to create a new SPN
# If the SPN doesn't exists, create one and store the password in KeyVault. Secret name is the SPN app Name
spn=$(az ad sp list --show-mine --output tsv --query "[?displayName=='$spn_appname'].[displayName,appId,appOwnerTenantId]")

if [ "$spn" == "" ]; then
    status "Generate a new SPN"
    secret=$(az ad sp create-for-rbac --name $spn_appname --years 1 | jq -r '.password')
    status "Store secret in Key Vault $key_vault under secret name $spn_appname"
    az keyvault secret set --vault-name $key_vault --name "$spn_appname" --value $secret --output table
    spn=$(az ad sp list --show-mine --output tsv --query "[?displayName=='$spn_appname'].[displayName,appId,appOwnerTenantId]")
else
    status "SPN $spn_appname exists, make sure its secret is stored in $key_vault"
    secret=$(az keyvault secret show --name $spn_appname --vault-name $key_vault -o json | jq -r '.value')
    if [ "$secret" == "" ]; then
        status "No secret stored in $key_vault for $spn_appname, appending a new secret"
        secret=$(az ad sp credential reset --append -n TotalCycleCloud --credential-description "azhpc" | jq -r '.password')
        status "Store new secret in Key Vault $key_vault under secret name $spn_appname"
        az keyvault secret set --vault-name $key_vault --name "$spn_appname" --value $secret --output table
    fi

fi

status "getting FQDN for $vmname"
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

status "Creating storage account $projectstore for projects"
az storage account create \
    --name $projectstore \
    --sku Standard_LRS \
    --resource-group $resource_group \
    --kind StorageV2 \
    --output table

# If no password is stored, create a random one
password=$(az keyvault secret show --name "CycleAdminPassword" --vault-name $key_vault -o json | jq -r '.value')
if [ "$password" == "" ]; then
    status "No secret CycleAdminPassword retrieved from Key Vault $key_vault"
    status "Generate a password"
    # Prefix password by a * so that the prequisites for Cycle are met (3 of : Capital Case + Lower Case + Number + Extra)
    password="*$(date +%s | sha256sum | base64 | head -c 16 ; echo)"
    status "Store password in Key Vault $key_vault secret CycleAdminPassword"
    az keyvault secret set --vault-name $key_vault --name "CycleAdminPassword" --value "$password" --output table
fi

secret=$(az keyvault secret show --name $spn_appname --vault-name $key_vault -o json | jq -r '.value')
if [ "$secret" == "" ]; then
    error "no secret stored in $key_vault for $spn_appname"
fi

appId=$(echo $spn | cut -d' ' -f2)
tenantId=$(echo $spn | cut -d' ' -f3)
status "Get cyclecloud_install.py"
downloadURL="https://cyclecloudarm.azureedge.net/cyclecloudrelease"
release="latest"
wget -q "$downloadURL/$release/cyclecloud_install.py" -O cyclecloud_install.py

status "Run cyclecloud_install.py on $fqdn"
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

status "CycleCloud application server installation finished"
status "Navigate to https://$fqdn and login using $admin_user"

if [ "$config" == "" ]; then
    $DIR/cyclecli_install.sh $fqdn $admin_user "$password" $resource_group
else
    status "running the cycle_install script on install node"

    config_file_no_path=${config##*/}
    config_file_no_path_or_extension=${config_file_no_path%.*}
    tmp_dir=azhpc_install_$config_file_no_path_or_extension
    azhpc-run -c $config $tmp_dir/scripts/cyclecli_install.sh $fqdn $admin_user "$password" $resource_group
fi

