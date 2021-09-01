#!/bin/bash

yum install -y /apps/rpms/slurm-*

export SLURMUSER=1002
groupadd -g $SLURMUSER slurm
useradd  -m -c "SLURM workload manager" -d /var/lib/slurm -u $SLURMUSER -g slurm  -s /bin/bash slurm

mkdir -p /var/spool/slurm
chown slurm /var/spool/slurm
mkdir -p /var/log/slurm
chown slurm /var/log/slurm

ln -sv /apps/slurm/slurm.conf /etc/slurm/slurm.conf
ln -sv /apps/slurm/cgroup.conf /etc/slurm/cgroup.conf
ln -sv /apps/slurm/plugstack.conf /etc/slurm/plugstack.conf
ln -sv /apps/slurm/plugstack.conf.d /etc/slurm/plugstack.conf.d

# Collect the actual hardware configuration of the node

slurmd -C | grep $HOSTNAME > /apps/slurm/nodeconf/$HOSTNAME

systemctl enable slurmd

exit 0
