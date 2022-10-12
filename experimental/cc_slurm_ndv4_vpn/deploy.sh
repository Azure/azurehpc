#!/bin/bash
# Deploys a A100 SLURM cluster on CycleCloud

set -o errexit
set -o nounset
set -o pipefail

print_formatted() {
    printf " $1 \n\n"
}

print_formatted "Deploying a CycleCloud Cluster"
print_formatted "------------------------------"

# Load variables from .envrc
source .envrc

# Setup Key Vault, ANF, and accept terms
print_formatted "\t1. Preparing Key Vault, ANF, and accepting terms of use"
azhpc init -c prereqs.json -d $OUTPUT_DIR \
    --vars project_prefix=$PROJECT_PREFIX,\
location=$LOCATION,\
peer_vnet_resource_group=$PEER_VNET_RESOURCE_GROUP,\
peer_vnet_name=$PEER_VNET_NAME,\
resource_group=$RESOURCE_GROUP,\
key_vault=$KEY_VAULT,\
key_vault_resource_group=$KEY_VAULT_RESOURCE_GROUP,\
cc_password_secret_name=$CC_PW_NAME,\
vnet_address_prefix=$VNET_ADDRESS_PREFIX

# - Need to build in OUTPUT_DIR
pushd $OUTPUT_DIR > /dev/null
azhpc build -c prereqs.json

# Prep scripts for CycleCloud generation
print_formatted "\t2. Copying required scripts for CycleCloud"

cp ../slurm_cycle.txt .

mkdir -p scripts

BASE_SCRIPTS=${azhpc}/experimental/deploy_cycle_slurm_ndv4/scripts/
cp $BASE_SCRIPTS/* scripts/

GPU_CLOCK_SCRIPT=${azhpc_dir}/experimental/gpu_optimizations/max_gpu_app_clocks.sh
cp $GPU_CLOCK_SCRIPT scripts/

NHC_SCRIPTS=${azhpc_dir}/experimental/cc_slurm_nhc/cc_slurm_nhc/specs/default/cluster-init/files
cp $NHC_SCRIPTS/* scripts/
# do not need prolog.sh per readme for deploy_cycle_slurm_ndv4
rm -f scripts/prolog.sh

PYXIS_SCRIPTS=${azhpc_dir}/experimental/cc_slurm_pyxis_enroot/cc_slurm_pyxis_enroot/specs/default/cluster-init/files
print_formatted "Copying ${PYXIS_SCRIPTS}"
cp $PYXIS_SCRIPTS/* scripts/

popd > /dev/null

# Deploy NDv4 cluster with CycleCloud
print_formatted "\t3. Deploy cluster using CycleCloud"
azhpc init -c config.json -d $OUTPUT_DIR \
    --vars project_prefix=$PROJECT_PREFIX,\
location=$LOCATION,\
resource_group=$RESOURCE_GROUP,\
projectstore=$PROJECT_STORE,\
key_vault=$KEY_VAULT,\
cc_password_secret_name=$CC_PW_NAME

# - Need to build in OUTPUT_DIR
pushd $OUTPUT_DIR > /dev/null
azhpc build -c config.json --no-vnet
popd > /dev/null