#!/bin/bash

glusterfs_mounthost=$(jetpack config glusterfs.mount_host)
glusterfs_mount_pt=$(jetpack config glusterfs

. $CYCLECLOUD_PROJECT_PATH/$CYCLECLOUD_SPEC_NAME/files/glusterfs_client.sh $glusterfs_mounthost $glusterfs_mount_pt
