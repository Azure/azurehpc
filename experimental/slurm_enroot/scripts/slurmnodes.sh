#!/bin/bash

cat /apps/slurm/nodeconf/* | sort > /apps/slurm/nodes.conf
partition=compute

echo "PartitionName=${partition} Nodes=ALL Default=YES MaxTime=INFINITE State=UP" > /apps/slurm/partitions.conf

systemctl restart slurmctld