#!/bin/bash

RESOURCEGROUP=$1

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
SuspendTimeout=300
ResumeTimeout=300
ResumeRate=0
#SuspendExcNodes=
#SuspendExcParts=
SuspendRate=0
SuspendTime=300
SchedulerParameters=salloc_wait_nodes
SlurmctldParameters=cloud_dns,idle_on_node_suspend
CommunicationParameters=NoAddrCache
DebugFlags=PowerSave
PrivateData=cloud

EOF

mkdir -p /apps/slurm/scripts
chown slurm /apps/slurm/scripts

#cp scripts/slurm/resume.sh /apps/slurm/scripts/

cat <<EOF >> /apps/slurm/scripts/resume.sh
#!/bin/bash

NODES=""
NODENAMES=\$1
RESOURCEGROUP="NOT-SET"

az login --identity -o table >> /var/log/slurm/autoscale.log

echo "running resume at \`date\` with options \$@" >> /var/log/slurm/autoscale.log

hosts=\`scontrol show hostnames \$1\`
for host in \$hosts
do
   NODE_ID=\`az vm show -g \${RESOURCEGROUP} -n \${host} --query id -o tsv\`
   if [ ! -z "\$NODE_ID" ]; then
     echo node_id is \$NODE_ID
     NODES+="\$NODE_ID "
     echo \$NODES >> /var/log/slurm/autoscale.log
   else
     echo need to create \$host
     SKU=\`scontrol show node \$host | grep AvailableFeatures | awk -F "=" '{print \$2}' | awk -F "," '{print \$1}'\`
     IMAGE=\`scontrol show node \$host | grep Partitions | awk -F "=" '{print \$2}'\`
     echo az vm create -n \$host --image \${IMAGE} -g \${RESOURCEGROUP} --admin-username hpcadmin --generate-ssh-keys --size \${SKU} --public-ip-address \"\" --nsg \"\" >> /var/log/slurm/autoscale.log
     az vm create -n \$host --image \${IMAGE} -g \${RESOURCEGROUP} --admin-username hpcadmin --generate-ssh-keys --size \${SKU} --public-ip-address "" --nsg "" -o table >> /var/log/slurm/autoscale.log
     az vm wait -g \${RESOURCEGROUP} -n \$host --created
   fi
done

if [ ! -z "\$NODES" ]; then
  echo az vm start --ids \$NODES >> /var/log/slurm/autoscale.log
  az vm start --ids \$NODES
fi 

for host in \$hosts
do
   NODEIP=\`az vm list-ip-addresses -g \${RESOURCEGROUP} -n \${host} | jq -r '.[].virtualMachine.network.privateIpAddresses[0]'\`
   echo scontrol update nodename=\${host} nodeaddr=\${NODEIP} >> /var/log/slurm/autoscale.log
   scontrol update nodename=\${host} nodeaddr=\${NODEIP}
done
EOF

cat <<EOF >> /apps/slurm/scripts/suspend.sh
#!/bin/bash

RESOURCEGROUP="NOT-SET"
NODES=""

az login --identity

echo "running suspend at \`date\` with options \$@" >> /var/log/slurm/autoscale.log

hosts=\`scontrol show hostnames \$1\`
for host in \$hosts
do
   NODES+=\`az vm show -g \${RESOURCEGROUP} -n \${host} --query id -o tsv\`
   NODES+=" "
   echo \$NODES >> /var/log/slurm/autoscale.log
done


echo az vm deallocate --ids \$NODES  >> /var/log/slurm/autoscale.log
az vm deallocate --ids \$NODES
EOF

chmod +x /apps/slurm/scripts/*.sh
ls -alh /apps/slurm/scripts
sed -i "s/RESOURCEGROUP=.*/RESOURCEGROUP=${RESOURCEGROUP}/g" /apps/slurm/scripts/resume.sh
sed -i "s/RESOURCEGROUP=.*/RESOURCEGROUP=${RESOURCEGROUP}/g" /apps/slurm/scripts/suspend.sh

systemctl enable slurmctld
#systemctl start slurmctld


exit 0
