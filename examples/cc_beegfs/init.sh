#/bin/bash
block_dir=$azhpc_dir/experimental/blocks
AZHPC_CONFIG=config.json
AZHPC_VARIABLES=variables.json

uuid_str="$(cat /proc/sys/kernel/random/uuid | tr -d '\n-' | tr '[:upper:]' '[:lower:]' | cut -c 1-6)"
locker="locker$uuid_str"

jq '.projectstore=$locker' --arg locker $locker $AZHPC_VARIABLES > temp.json
cp temp.json $AZHPC_VARIABLES

cat <<EOF >$AZHPC_CONFIG
{}
EOF

function init_and_merge_config()
{
    local config=$1
    azhpc-init -d . -c $config
    config_file=${config##*/}

    # Merge config files
    cp $AZHPC_CONFIG temp.json
    jq -s '.[0] * .[1]' temp.json $config_file > $AZHPC_CONFIG
}

blocks="vnet.json jumpbox.json cycle-prereqs-managed-identity.json cycle-install-server-managed-identity.json cycle-cli-local.json cycle-cli-jumpbox.json beegfs-cluster.json"

for block in $blocks; do
    echo "initializing config for $block"
    init_and_merge_config $block_dir/$block
done

# Concatenate install array into a single one
jq -s '[.[].install[]]' $blocks > install.json

# Replace the install array into the final config file
items=$(cat install.json)
jq '.install=$items' --argjson items "$items" $AZHPC_CONFIG > temp.json
cp temp.json $AZHPC_CONFIG

# Init cycle config file
init_and_merge_config $azhpc_dir/examples/cc_beegfs/pbscycle.json
init_and_merge_config $azhpc_dir/examples/cc_beegfs/slurmcycle.json

# Merge variables file into config file
cp $AZHPC_CONFIG temp.json
jq '.variables+=$variables' --argjson variables "$(cat $AZHPC_VARIABLES)" temp.json > $AZHPC_CONFIG

cp cycle-prereqs-managed-identity.json temp.json
jq '.variables+=$variables' --argjson variables "$(cat $AZHPC_VARIABLES)" temp.json > cycle-prereqs-managed-identity.json

# Update locker name
sed -i "s/#projectstore#/$locker/g" $AZHPC_CONFIG
