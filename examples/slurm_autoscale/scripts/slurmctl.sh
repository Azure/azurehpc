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
cp /etc/slurm/slurm.conf.example /apps/slurm/slurm.conf
ln -s /apps/slurm/slurm.conf /etc/slurm/slurm.conf
sed -i "s/ControlMachine=.*/ControlMachine=`hostname -s`/g" /apps/slurm/slurm.conf
sed -i "s/SlurmctldLogFile=.*/SlurmctldLogFile=\/var\/log\/slurm\/slurmctld.log/" /apps/slurm/slurm.conf
sed -i "s/NodeName=linux.*/include \/apps\/slurm\/nodes.conf/g" /apps/slurm/slurm.conf
echo "# NODES" > /apps/slurm/nodes.conf
sed -i "s/PartitionName=debug.*/include \/apps\/slurm\/partition.conf/g" /apps/slurm/slurm.conf
echo "#PARTITIONS" > /apps/slurm/partition.conf

cat <<EOF >> /etc/slurm/slurm.conf

# POWER SAVE SUPPORT FOR IDLE NODES (optional)
SuspendProgram=/apps/slurm/scripts/suspend.sh
ResumeProgram=/apps/slurm/scripts/resume.sh
ResumeFailProgram=/apps/slurm/scripts/suspend.sh
SuspendTimeout=1800
ResumeTimeout=600
ResumeRate=0
#SuspendExcNodes=
#SuspendExcParts=
SuspendRate=0
SuspendTime=300
SchedulerParameters=salloc_wait_nodes
SlurmctldParameters=cloud_dns,idle_on_node_suspend
CommunicationParameters=NoAddrCache
DebugFlags=PowerSave

EOF

mkdir -p /apps/slurm/scripts
chown slurm /apps/slurm/scripts

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
