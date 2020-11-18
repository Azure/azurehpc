#!/bin/bash
block_dir=$azhpc_dir/blocks
AZHPC_CONFIG=config.json
AZHPC_VARIABLES=variables.json

blocks="$block_dir/vnet.json $block_dir/jumpbox-nfs.json $block_dir/cycle-install-server-managed-identity.json $block_dir/cycle-cli-local.json $block_dir/cycle-cli-jumpbox.json"

# Initialize config file
echo "{}" >$AZHPC_CONFIG
$azhpc_dir/init-and-merge.sh "$blocks" $AZHPC_CONFIG $AZHPC_VARIABLES

echo "{}" >prereqs.json
prereqs="$block_dir/cycle-prereqs-managed-identity.json"
$azhpc_dir/init-and-merge.sh $prereqs prereqs.json $AZHPC_VARIABLES

# Update locker name
locker=$(azhpc-get -c $AZHPC_VARIABLES variables.projectstore | cut -d '=' -f2 | xargs)
sed -i "s/#projectstore#/$locker/g" $AZHPC_CONFIG

# Accept the licence term of the Cycle Markeplace image
cc_image=$(azhpc-get -c $AZHPC_VARIABLES variables.cc_image | cut -d '=' -f2 | xargs)
az vm image terms accept --urn $cc_image
