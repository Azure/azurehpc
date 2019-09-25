#!/bin/bash
#

num_hdd_targets=$1
BEEGFS_SHARE=/beegfs

cnt=$((num_hdd_targets*2))
hdd_target_str=$(seq -s, 1 2 $cnt)
beegfs-ctl --addstoragepool --desc="hdd_pool" --targets=$hdd_target_str
HDD_POOL_DIR=${BEEGFS_SHARE}/hdd_pool
mkdir $HDD_POOL_DIR
chmod 777 $HDD_POOL_DIR
beegfs-ctl --setpattern --storagepoolid=2 ${BEEGFS_SHARE}/hdd_pool
