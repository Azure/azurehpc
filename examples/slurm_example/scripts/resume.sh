#!/bin/bash

NODES=$1

echo "$(date) : [resume.sh] : running resume with options $@" >> /var/log/slurm/autoscale.log

cd /var/lib/slurm

az login --identity -o table
azhpc-build 

for host in $(scontrol show hostnames $NODES)
do
   NODEIP=`az vm list-ip-addresses -g ${RESOURCEGROUP} -n ${host} | jq -r '.[].virtualMachine.network.privateIpAddresses[0]'`
   echo "$(date) : [resume.sh] : scontrol update nodename=${host} nodeaddr=${NODEIP}" >> /var/log/slurm/autoscale.log
   scontrol update nodename=${host} nodeaddr=${NODEIP}
done

echo "$(date) : [resume.sh] : exiting" >> /var/log/slurm/autoscale.log
