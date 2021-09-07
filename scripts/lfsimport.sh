#!/bin/bash

# arg: $1 = storage account
# arg: $2 = storage sas
# arg: $3 = storage container
# arg: $3 = lfs mount
# arg: $4 = lustre mount (default=/lustre)
storage_account="$1"
storage_sas="$2"
storage_container="$3"
lfs_mount=${4:-/lustre}

if ! rpm -q lemur-azure-hsm-agent lemur-azure-data-movers; then
    yum -y install \
        https://azurehpc.azureedge.net/rpms/lemur-azure-hsm-agent-2.0.0-lustre_2.12.x86_64.rpm \
        https://azurehpc.azureedge.net/rpms/lemur-azure-data-movers-2.0.0-lustre_2.12.x86_64.rpm
fi

cd $lfs_mount
export STORAGE_SAS="?$storage_sas"
/sbin/azure-import -account ${storage_account} -container ${storage_container}

