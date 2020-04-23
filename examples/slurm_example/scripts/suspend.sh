#!/bin/bash

RESOURCEGROUP=paul-slurm-test
NODES=""

echo "$(date) : [suspend.sh] : running suspend with options $@" >> /var/log/slurm/autoscale.log

az login --identity

hosts=`scontrol show hostnames $1`
for host in $hosts
do
   NODES+=`az vm show -g ${RESOURCEGROUP} -n ${host} --query id -o tsv`
   NODES+=" "
   echo "$(date) : [suspend.sh] : nodes = $NODES" >> /var/log/slurm/autoscale.log
done

echo az vm deallocate --ids $NODES
az vm deallocate --ids $NODES

echo "$(date) : [suspend.sh] : exiting" >> /var/log/slurm/autoscale.log