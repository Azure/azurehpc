#/bin/bash
uuid_str="$(cat /proc/sys/kernel/random/uuid | tr -d '\n-' | tr '[:upper:]' '[:lower:]' | cut -c 1-6)"
locker="locker$uuid_str"

jq '.projectstore=$locker' --arg locker $locker variables.json > temp.json
cp temp.json variables.json

cat <<EOF >config.json
{}
EOF

function init_config()
{
    local config=$1
    azhpc-init -d . -c $config
    config_file=${config##*/}
    #cp $config_file temp.json
    #jq '.variables+=$variables' --argjson variables "$(cat variables.json)" temp.json > $config_file

    # Merge config files
    cp config.json temp.json
    jq -s '.[0] * .[1]' temp.json $config_file > config.json
}

blocks="vnet.json jumpbox.json cycle-prereqs-managed-identity.json cycle-install-server-managed-identity.json cycle-cli-local.json cycle-cli-jumpbox.json beegfs-cluster.json"

for block in $blocks; do
    echo "initializing config for $block"
    init_config $azhpc_dir/experimental/blocks/$block
done

# Update locker name
sed -i "s/#projectstore#/$locker/g" config.json

# Init cycle config file
init_config $azhpc_dir/examples/cc_beegfs/pbscycle.json

# Concatenate install array into a single one
jq -s '[.[].install[]]' $blocks > install.json

# Replace the install array into the final config file
items=$(cat install.json)
jq '.install=$items' --argjson items "$items" config.json > temp.json
cp temp.json config.json

# Merge variables file into config file
cp config.json temp.json
jq '.variables+=$variables' --argjson variables "$(cat variables.json)" temp.json > config.json
