#/bin/bash
uuid_str="$(cat /proc/sys/kernel/random/uuid | tr -d '\n-' | tr '[:upper:]' '[:lower:]' | cut -c 1-6)"
locker="locker$uuid_str"

jq '.projectstore=$locker' --arg locker $locker variables.json > temp.json
cp temp.json variables.json

function init_config()
{
    local config=$1
    azhpc-init -d . -c $config
    config_file=${config##*/}
    cp $config_file temp.json
    jq '.variables+=$variables' --argjson variables "$(cat variables.json)" temp.json > $config_file
}

blocks="vnet.json jumpbox.json cycle-prereqs-managed-identity.json cycle-install-server-managed-identity.json cycle-cli-local.json cycle-cli-jumpbox.json beegfs-cluster.json"
for block in $blocks; do
    echo "initializing config for $block"
    init_config $azhpc_dir/experimental/blocks/$block
done

init_config $azhpc_dir/examples/cc_beegfs/pbscycle.json
