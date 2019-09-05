#!/bin/bash
LSF_DOWNLOAD_DIR=/mnt/resource
LSF_INSTALL_DIR=$LSF_DOWNLOAD_DIR/lsf10.1_lsfinstall
LSF_INSTALL_CONFIG=$LSF_INSTALL_DIR/lsf.install.config
LSF_TOP=/apps/lsf
LSF_CONF=$LSF_TOP/conf/lsf.conf
CLUSTERNAME=azhpc
LSFADMIN=hpcadmin

# Install dependencies
yum -y install jre

# Fill up install configuration file
cp $LSF_INSTALL_DIR/install.config $LSF_INSTALL_CONFIG

echo "Updating install.config"
sed -i 's|# LSF_TOP="/usr/share/lsf"|LSF_TOP="'$LSF_TOP'"|g' $LSF_INSTALL_CONFIG
sed -i 's|# LSF_ADMINS="lsfadmin user1 user2"|LSF_ADMINS="'$LSFADMIN'"|g' $LSF_INSTALL_CONFIG
sed -i 's|# LSF_CLUSTER_NAME="cluster1"|LSF_CLUSTER_NAME="'$CLUSTERNAME'"|g' $LSF_INSTALL_CONFIG
sed -i 's|# LSF_MASTER_LIST="hostm hosta hostc"|LSF_MASTER_LIST="'$(hostname)'"|g' $LSF_INSTALL_CONFIG
sed -i 's|# LSF_ENTITLEMENT_FILE="/usr/share/lsf/lsf_distrib/lsf_std_entitlement.dat"|LSF_ENTITLEMENT_FILE="'$LSF_DOWNLOAD_DIR'/lsf_std_entitlement.dat"|g' $LSF_INSTALL_CONFIG
sed -i 's|# LSF_TARDIR="/usr/share/lsf_distrib/"|LSF_TARDIR="'$LSF_DOWNLOAD_DIR'"|g' $LSF_INSTALL_CONFIG
sed -i 's/# CONFIGURATION_TEMPLATE="DEFAULT|PARALLEL|HIGH_THROUGHPUT"/CONFIGURATION_TEMPLATE="PARALLEL"/g' $LSF_INSTALL_CONFIG
sed -i 's|# SILENT_INSTALL="Y"|SILENT_INSTALL="Y"|g' $LSF_INSTALL_CONFIG
sed -i 's|# LSF_SILENT_INSTALL_TARLIST=""|LSF_SILENT_INSTALL_TARLIST="All"|g' $LSF_INSTALL_CONFIG
sed -i 's|# ACCEPT_LICENSE="N"|ACCEPT_LICENSE="Y"|g' $LSF_INSTALL_CONFIG
#sed -i 's|# ENABLE_EGO="N"|ENABLE_EGO="Y"|g' $LSF_INSTALL_CONFIG
#sed -i 's|# EGO_DAEMON_CONTROL="N"|EGO_DAEMON_CONTROL="Y"|g' $LSF_INSTALL_CONFIG
sed -i 's|# ENABLE_DYNAMIC_HOSTS="N"|ENABLE_DYNAMIC_HOSTS="Y"|g' $LSF_INSTALL_CONFIG
sed -i 's|# LSF_DYNAMIC_HOST_WAIT_TIME="60"|LSF_DYNAMIC_HOST_WAIT_TIME="60"|g' $LSF_INSTALL_CONFIG

echo "Installing"
pushd $LSF_INSTALL_DIR
./lsfinstall -f $LSF_INSTALL_CONFIG

cat Install.err
cat Install.log

echo "Apply patch"
pushd $LSF_TOP/10.1
tar zxvf $LSF_DOWNLOAD_DIR/lsf10.1_linux2.6-glibc2.3-x86_64-509238.tar.Z


cat << EOF >> /etc/lsf.sudoers
LSF_STARTUP_USERS="$LSFADMIN"
LSF_STARTUP_PATH="$LSF_TOP/10.1/linux2.6-glibc2.3-x86_64/etc"
EOF

chmod 0600 /etc/lsf.sudoers

cat << EOF >> /etc/profile.d/lsf.sh
source $LSF_TOP/conf/profile.lsf
EOF

chmod 0644 /etc/profile.d/lsf.sh

chown -R root:root $LSF_TOP
chmod 4755 $LSF_TOP/10.1/linux2.6-glibc2.3-x86_64/bin/lsadmin
chmod 4755 $LSF_TOP/10.1/linux2.6-glibc2.3-x86_64/bin/badmin

chown -R $LSFADMIN:$LSFADMIN $LSF_TOP/work/$CLUSTERNAME/

cat << EOF >> /etc/security/limits.conf
* soft nofile 65535
* hard nofile 65535
EOF

# Update lsf.conf
#sed -i 's|LSF_ENABLE_EGO=Y|LSF_ENABLE_EGO=N|g' $LSF_CONF
master_domain=$(hostname -d)

cat << EOF >> $LSF_CONF

LSF_RSH="ssh -o 'PasswordAuthentication no' -o 'StrictHostKeyChecking no'"
LSF_STRIP_DOMAIN=.$master_domain
LSF_DYNAMIC_HOST_TIMEOUT=10m
EOF

