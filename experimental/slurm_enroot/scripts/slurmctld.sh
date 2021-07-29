#!/bin/bash

yum install -y epel-release screen

yum install python3 perl-ExtUtils-MakeMaker gcc mariadb-devel openssl openssl-devel pam-devel rpm-build numactl numactl-devel hwloc hwloc-devel lua lua-devel readline-devel rrdtool-devel ncurses-devel man2html libibmad libibumad -y

slurm_version=${1:-20.11.8}
slurm_tarball=slurm-${slurm_version}.tar.bz2
if [ ! -f $slurm_tarball ]; then
  wget https://download.schedmd.com/slurm/$slurm_tarball
fi

if [ ! -f "/apps/rpms/slurm*.rpm" ]; then
  rpmbuild -ta $slurm_tarball
  mkdir -p /apps/rpms
  cp /root/rpmbuild/RPMS/x86_64/slurm-* /apps/rpms/
fi

yum install -y /apps/rpms/slurm-*

export SLURMUSER=1002
groupadd -g $SLURMUSER slurm
useradd  -m -c "SLURM workload manager" -d /var/lib/slurm -u $SLURMUSER -g slurm  -s /bin/bash slurm

mkdir -p /var/spool/slurm
chown slurm /var/spool/slurm
mkdir -p /var/log/slurm
chown slurm /var/log/slurm
mkdir -p /apps/slurm

# Create slurm.conf
cat <<EOF > /apps/slurm/slurm.conf
ClusterName=cluster

SlurmctldHost=`hostname -s`
SlurmUser=slurm
SlurmctldPort=6817
SlurmdPort=6818
SlurmctldPidFile=/var/run/slurmctld.pid
SlurmdPidFile=/var/run/slurmd.pid
SlurmdSpoolDir=/var/spool/slurm
StateSaveLocation=/var/spool/slurm/state

AuthType=auth/munge

ProctrackType=proctrack/cgroup
TaskPlugin=task/affinity,task/cgroup

SelectType=select/cons_res
SelectTypeParameters=CR_CPU_Memory

SchedulerType=sched/backfill
SchedulerParameters=salloc_wait_nodes

SuspendTime=300
SuspendTimeout=600
ResumeTimeout=1800
#SuspendProgram=/apps/slurm/scripts/suspend.sh
#ResumeProgram=/apps/slurm/scripts/resume.sh
#ResumeFailProgram=/apps/slurm/scripts/suspend.sh

SlurmctldTimeout=300
SlurmdTimeout=300

#SlurmctldParameters=cloud_dns,idle_on_node_suspend
#CommunicationParameters=NoAddrCache

PropagateResourceLimits=NONE

SlurmctldLogFile=/var/log/slurm/slurmctld.log
SlurmctldDebug=debug5
SlurmdLogFile=/var/log/slurm/slurmd.log
SlurmdDebug=debug5
DebugFlags=PowerSave

PrivateData=cloud
ReturnToService=2

LaunchParameters=use_interactive_step
#InteractiveStepOptions=--mem-per-cpu=0 --cpu_bind=no --preserve-env --pty /bin/bash

include /apps/slurm/nodes.conf
include /apps/slurm/partitions.conf

EOF

# Create cgroup.conf
cat <<EOF > /apps/slurm/cgroup.conf
CgroupMountpoint=/sys/fs/cgroup
CgroupAutomount=yes
ConstrainCores=yes
TaskAffinity=no
ConstrainRAMSpace=yes
ConstrainSwapSpace=no
ConstrainDevices=no

EOF

# Create plugstack.conf
cat <<EOF > /apps/slurm/plugstack.conf
include /etc/slurm/plugstack.conf.d/*

EOF

mkdir -pv /apps/slurm/plugstack.conf.d

ln -sv /apps/slurm/slurm.conf /etc/slurm/slurm.conf
ln -sv /apps/slurm/cgroup.conf /etc/slurm/cgroup.conf
ln -sv /apps/slurm/plugstack.conf /etc/slurm/plugstack.conf
ln -sv /apps/slurm/plugstack.conf.d /etc/slurm/plugstack.conf.d

chown slurm.slurm -R /apps/slurm
mkdir -pv /apps/slurm/nodeconf 

systemctl enable slurmctld

exit 0
