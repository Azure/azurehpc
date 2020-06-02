#!/bin/bash

beegfs_mgmthost=$(jetpack config beegfs.mgmt_host)
. $CYCLECLOUD_PROJECT_PATH/beegfs-client/files/beegfsc.sh $beegfs_mgmthost
