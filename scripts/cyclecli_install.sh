#!/bin/bash
set -e
fqdn=$1
admin_user=$2
password=$3
resource_group=$4
cyclecloud_storage_key=$5

# Installing CycleCloud CLI
echo "Getting CLI binaries..."
wget --no-check-certificate https://$fqdn/download/tools/cyclecloud-cli.zip 

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

    cat <<EOF >> $pogo_config_file

[pogo ${cyclecloud_storage_account}-storage]
type=az
matches=az://$cyclecloud_storage_account/cyclecloud
access_key=$cyclecloud_storage_key
EOF

echo "pogo.ini file created"

fi

