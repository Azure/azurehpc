#!/bin/bash
anfmountpoint=$(jetpack config anf.mountpoint)
anfmountpath=$(jetpack config anf.mountpath)

. $CYCLECLOUD_PROJECT_PATH/$CYCLECLOUD_SPEC_NAME/files/auto-netappfiles-mount.sh $anfmountpoint $anfmountpath
