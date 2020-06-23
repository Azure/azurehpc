#/bin/bash
block_dir=$azhpc_dir/blocks
AZHPC_CONFIG=config.json
AZHPC_VARIABLES=variables.json

# Ensure that jq is installed
command -v jq &> /dev/null || { echo -e >&2 "ERROR: Missing requirement: jq\nMake sure it is installed and its installation path included in PATH before executing $0"; exit 1; }

blocks="$block_dir/vnet.json $block_dir/jumpbox-nfs.json $block_dir/cycle-install-server-managed-identity.json $block_dir/cycle-cli-local.json $block_dir/cycle-cli-jumpbox.json $block_dir/beegfs-cluster.json"

# Select scheduler to be installed
if $(jq '.variables.scheduler == "pbs"' variables.json); then
  blocks="$blocks $azhpc_dir/examples/cc_beegfs/pbscycle.json"
elif $(jq '.variables.scheduler == "slurm"' variables.json); then
  blocks="$blocks $azhpc_dir/examples/cc_beegfs/slurmcycle.json"
else
  echo 'ERROR: Unsupported scheduler type'
  exit 1
fi

# Initialize config file
echo "{}" >$AZHPC_CONFIG
$azhpc_dir/init-and-merge.sh "$blocks" $AZHPC_CONFIG $AZHPC_VARIABLES

echo "{}" >prereqs.json
prereqs="$block_dir/cycle-prereqs-managed-identity.json"
$azhpc_dir/init-and-merge.sh $prereqs prereqs.json $AZHPC_VARIABLES

# Update locker name
locker=$(azhpc-get -c $AZHPC_VARIABLES variables.projectstore | cut -d '=' -f2 | xargs)
sed -i "s/#projectstore#/$locker/g" $AZHPC_CONFIG
