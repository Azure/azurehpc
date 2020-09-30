#!/bin/bash

yum install -y epel-release screen

yum install perl-ExtUtils-MakeMaker gcc mariadb-devel openssl openssl-devel pam-devel rpm-build numactl numactl-devel hwloc hwloc-devel lua lua-devel readline-devel rrdtool-devel ncurses-devel man2html libibmad libibumad -y

if [ ! -f "slurm-19.05.5.tar.bz2" ]; then
  wget https://download.schedmd.com/slurm/slurm-19.05.5.tar.bz2
fi

if [ ! -f "/apps/rpms/slurm*.rpm" ]; then
  rpmbuild -ta slurm-19.05.5.tar.bz2
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
SuspendProgram=/apps/slurm/scripts/suspend.sh
ResumeProgram=/apps/slurm/scripts/resume.sh
ResumeFailProgram=/apps/slurm/scripts/suspend.sh

SlurmctldTimeout=300
SlurmdTimeout=300

SlurmctldParameters=cloud_dns,idle_on_node_suspend
CommunicationParameters=NoAddrCache

PropagateResourceLimits=NONE

SlurmctldLogFile=/var/log/slurm/slurmctld.log
SlurmctldDebug=debug5
SlurmdLogFile=/var/log/slurm/slurmd.log
SlurmdDebug=debug5
DebugFlags=PowerSave

PrivateData=cloud
ReturnToService=2

SallocDefaultCommand="srun --mem-per-cpu=0 --cpu_bind=no --preserve-env --pty $SHELL"

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

ln -s /apps/slurm/slurm.conf /etc/slurm/slurm.conf
ln -s /apps/slurm/cgroup.conf /etc/slurm/cgroup.conf

mkdir -p /apps/slurm/scripts

cp scripts/suspend.sh /apps/slurm/scripts/
cp scripts/resume.sh /apps/slurm/scripts/

chmod +x /apps/slurm/scripts/*.sh
ls -alh /apps/slurm/scripts

mkdir -p /apps/slurm/azscale/scripts
cp scripts/config.json /apps/slurm/azscale
cp scripts/*_id_rsa* /apps/slurm/azscale
chmod 600 /apps/slurm/azscale/*_id_rsa
chmod 644 /apps/slurm/azscale/*_id_rsa.pub
cp -r scripts /apps/slurm/azscale/.
pushd /apps/slurm
git clone https://github.com/Azure/azurehpc.git
popd

chown slurm.slurm -R /apps/slurm

systemctl enable slurmctld

exit 0
