#!/bin/bash
#
BEEGFS_MGMT=$1
#
yum install -y xauth
yum install -y beegfs-admon
mkdir -p $BEEGFS_MGMT
sed -i 's/^sysMgmtdHost.*/sysMgmtdHost = '$MGMT_MGMT'/g' /etc/beegfs/beegfs-admon.conf
#
systemctl start beegfs-admon.service
