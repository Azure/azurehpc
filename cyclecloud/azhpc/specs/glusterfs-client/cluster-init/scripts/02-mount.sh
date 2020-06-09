#!/bin/bash

#glusterfs_mounthost=$(jetpack config glusterfs.mount_host)
#glusterfs_mount_pt=$(jetpack config glusterfs.mount_point)

glusterfs_mounthost=${1:-glusterfs000000}
glusterfs_mount_pt=${2:-/glusterfs}

. $CYCLECLOUD_PROJECT_PATH/$CYCLECLOUD_SPEC_NAME/files/glusterfs_client.sh $glusterfs_mounthost $glusterfs_mount_pt
