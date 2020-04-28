#!/bin/bash

HOSTLIST=$1
STRIPE=$2
REPLICA=$3

BRICK_MOUNT_PT=${BRICK_MOUNT_PT:-/mnt/brick1}

GLUSTERFS_VOL_NAME=gv0

mkdir -p ${BRICK_MOUNT_PT}/$GLUSTERFS_VOL_NAME

if [ "$PSSH_NODENUM" = "0" ]; then
   for host in $HOSTLIST
   do
      hosts_str=${hosts_str}"$host:${BRICK_MOUNT_PT}/$GLUSTERFS_VOL_NAME "
   done
   echo $hosts_str

   stripe_str=""
   if [ $STRIPE -gt 1 ]; then
      stripe_str="stripe $STRIPE"
   fi

   replica_str=""
   if [ $REPLICA -gt 0 ]; then
      replica_str="replica $REPLICA"
   fi

   gluster volume create $GLUSTERFS_VOL_NAME $stripe_str $replica_str $hosts_str

   gluster volume start $GLUSTERFS_VOL_NAME

   gluster volume info
fi
