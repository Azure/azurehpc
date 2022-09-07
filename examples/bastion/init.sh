#!/bin/bash

# Ensure that jq is installed
command -v jq &> /dev/null || { echo -e >&2 "ERROR: Missing requirement: jq\nMake sure it is installed and its installation path included in PATH before executing $0"; exit 1; }

# Find Linux distro from image name
os_image=$(jq -r '.variables.jumpbox_image' variables.json)
shopt -s nocasematch
if [[ "$os_image" =~ "centos" ]]; then
    os_type=centos
elif [[ "$os_image" =~ "ubuntu" ]]; then
    os_type=ubuntu
else
    echo "ERROR: Unsupported Linux distribution of image: $os_image"
    exit 1
fi

# Create prerequisites configuration file
echo "{}" > prereqs.json
prereqs="$azhpc_dir/blocks/keyvault-secret.json"
$azhpc_dir/init-and-merge.sh $prereqs prereqs.json variables.json

# Create config file
echo "{}" > config.json
$azhpc_dir/init-and-merge.sh ./templates/config-template.json config.json variables.json
ci_file="@templates/cloud-init-${os_type}.txt"
jq --arg cif "$ci_file" '.variables.customdata = $cif' config.json > config.tmp && mv config.tmp config.json

# Just a little cleanup...
rm -f keyvault-secret.json config-template.json
