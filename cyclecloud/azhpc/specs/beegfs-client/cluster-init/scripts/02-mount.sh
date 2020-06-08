#!/bin/bash

beegfs_mgmthost=$(jetpack config beegfs.mgmt_host)
. $CYCLECLOUD_PROJECT_PATH/$CYCLECLOUD_SPEC_NAME/files/beegfsc.sh $beegfs_mgmthost
