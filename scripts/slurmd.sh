#!/bin/bash

yum install -y /apps/rpms/slurm-*

export SLURMUSER=1002
groupadd -g $SLURMUSER slurm
useradd  -m -c "SLURM workload manager" -d /var/lib/slurm -u $SLURMUSER -g slurm  -s /bin/bash slurm

mkdir -p /var/spool/slurm
chown slurm /var/spool/slurm
mkdir -p /var/log/slurm
chown slurm /var/log/slurm

ln -s /apps/slurm/slurm.conf /etc/slurm/slurm.conf

sed -i "s/Delegate=yes.*/Delegate=yes\nExecStartPre=\/bin\/sleep 30/g" /lib/systemd/system/slurmd.service

systemctl daemon-reload
systemctl enable slurmd
#systemctl start slurmd

exit 0
