#/bin/bash
config_list="$1"
AZHPC_CONFIG=$2
AZHPC_VARIABLES=$3

if [ ! -e $AZHPC_CONFIG ]; then
    echo "destination config file '$AZHPC_CONFIG' is missing"
    exit 1
fi

if [ ! -e $AZHPC_VARIABLES ]; then
    echo "input variables file '$AZHPC_VARIABLES' is missing"
    exit 1
fi

function copy_and_merge_config()
{
    local config=$1
    cp $config .
    config_file=${config##*/}

    # Merge config files
    cp $AZHPC_CONFIG temp.json
    jq -s '.[0] * .[1]' temp.json $config_file > $AZHPC_CONFIG
}

for config in $config_list; do
    echo "initializing config for $config"
    copy_and_merge_config $config
done

# Concatenate install array into a single one
install_list=$(jq -s '[.[].install[]]' $config_list)

# Replace the install array into the final config file
jq '.install=$items' --argjson items "$install_list" $AZHPC_CONFIG > temp.json
cp temp.json $AZHPC_CONFIG

# Merge variables file into config file
cp $AZHPC_CONFIG temp.json
jq '.variables+=$variables' --argjson variables "$(jq '.variables' $AZHPC_VARIABLES)" temp.json > $AZHPC_CONFIG

rm temp.json