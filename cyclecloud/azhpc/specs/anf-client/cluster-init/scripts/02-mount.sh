#!/bin/bash

anfmountpoint=$(jetpack config anf.mountpoint)

. $CYCLECLOUD_PROJECT_PATH/$CYCLECLOUD_SPEC_NAME/files/replace_nfs_with_anf.sh $anfmountpoint
