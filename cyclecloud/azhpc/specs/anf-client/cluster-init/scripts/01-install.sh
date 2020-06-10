#!/bin/bash
anfmountpath=$(jetpack config anf.mountpath)
anfmountpoint=$(jetpack config anf.mountpoint)


. $CYCLECLOUD_PROJECT_PATH/$CYCLECLOUD_SPEC_NAME/files/auto-netappfiles-mount.sh $anfmountpath $anfmountpoint
