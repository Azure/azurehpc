#/bin/bash
block_dir=$azhpc_dir/experimental/blocks
AZHPC_CONFIG=config.json
AZHPC_VARIABLES=variables.json

uuid_str="$(cat /proc/sys/kernel/random/uuid | tr -d '\n-' | tr '[:upper:]' '[:lower:]' | cut -c 1-6)"
locker="locker$uuid_str"

jq '.variables.projectstore=$locker' --arg locker $locker $AZHPC_VARIABLES > temp.json
cp temp.json $AZHPC_VARIABLES

blocks="$block_dir/vnet.json $block_dir/jumpbox.json $block_dir/cycle-install-server-managed-identity.json $block_dir/cycle-cli-local.json $block_dir/cycle-cli-jumpbox.json $block_dir/beegfs-cluster.json $azhpc_dir/examples/cc_beegfs/pbscycle.json"

# Initialize config file
echo "{}" >$AZHPC_CONFIG
$azhpc_dir/init-and-merge.sh "$blocks" $AZHPC_CONFIG $AZHPC_VARIABLES

echo "{}" >prereqs.json
prereqs="$block_dir/cycle-prereqs-managed-identity.json"
$azhpc_dir/init-and-merge.sh $prereqs prereqs.json $AZHPC_VARIABLES

# Update locker name
sed -i "s/#projectstore#/$locker/g" $AZHPC_CONFIG
