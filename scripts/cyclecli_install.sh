#!/bin/bash
fqdn=$1
admin_user=$2
password=$3
resource_group=$4
cyclecloud_storage_key=$5

downloadURL="https://cyclecloudarm.azureedge.net/cyclecloudrelease"
release="latest"

# Installing CycleCloud CLI
echo "Getting CLI binaries..."
wget -q "$downloadURL/$release/cyclecloud-cli.zip"

unzip -o cyclecloud-cli.zip
pushd cyclecloud-cli-installer/
echo "Installing CLI..."
./install.sh -y

echo "Initializing CLI..."
name=$(echo $fqdn | cut -d'.' -f1)
echo $name
~/bin/cyclecloud initialize --force --batch \
    --name $name \
    --url=https://$fqdn \
    --verify-ssl=false \
    --username=$admin_user \
    --password="${password}"

~/bin/cyclecloud config list
popd
rm cyclecloud-cli.zip
rm -rf cyclecloud-cli-installer

# Setup POGO
cyclecloud_storage_account=$(~/bin/cyclecloud locker list  |  sed -e 's|^[^/]*//||' -e 's|/.*$||')
pogo_config_file=$HOME/.cycle/pogo.ini
touch $pogo_config_file
if ! grep -q "${cyclecloud_storage_account}-storage" $pogo_config_file; then
    echo "Creating ~/.cycle/pogo.ini"
    #cyclecloud_storage_key=$(az storage account keys list -g $resource_group -n $cyclecloud_storage_account --query "[0].value" | sed 's/\"//g')

    cat <<EOF >> $pogo_config_file

[pogo ${cyclecloud_storage_account}-storage]
type=az
matches=az://$cyclecloud_storage_account/cyclecloud
access_key=$cyclecloud_storage_key
EOF

echo "pogo.ini file created"

fi

