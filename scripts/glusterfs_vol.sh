#!/bin/bash

HOSTLIST=$1
REPLICA=$2

GLUSTERFS_VOL_NAME=glusterfs_vol

if [ "$PSSH_NODENUM" = "0" ]; then
   for host in `cat hostlists/$HOSTLIST`
   do
      hosts_str=${host_str}"$host:/mnt/resource_nvme "
   done
   echo $hosts_str

   replica_str=""
   if [ $REPLICA -gt 0 ]; then
      replica_str="replica $REPLICA"
   fi

   gluster volume create $GLUSTERFS_VOL_NAME $replica_str $hosts_str

   gluster volume start $GLUSTERFS_VOL_NAME

   gluster volume info
fi
