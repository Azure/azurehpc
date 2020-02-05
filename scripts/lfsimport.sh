#!/bin/bash

# arg: $1 = storage account
# arg: $2 = storage key
# arg: $3 = storage container
# arg: $3 = lfs mount
# arg: $4 = lustre mount (default=/lustre)
# arg: $5 = lustre version (default=2.10)
storage_account=$1
storage_key=$2
storage_container=$3
lfs_mount=${4:-/lustre}
lustre_version=${5-2.10}

if ! rpm -q lemur-azure-hsm-agent lemur-azure-data-movers; then
    yum -y install \
        https://azurehpc.azureedge.net/rpms/lemur-azure-hsm-agent-1.0.0-lustre_${lustre_version}.x86_64.rpm \
        https://azurehpc.azureedge.net/rpms/lemur-azure-data-movers-1.0.0-lustre_${lustre_version}.x86_64.rpm
fi

cd $lfs_mount
export STORAGE_ACCOUNT=$storage_account
export STORAGE_KEY=$storage_key
/sbin/azure-import ${storage_container}

