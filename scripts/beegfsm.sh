#!/bin/bash
#
BEEGFS_MGMT=$1
#
yum install -y beegfs-mgmtd beegfs-helperd beegfs-utils beegfs-admon
mkdir -p $BEEGFS_MGMT
sed -i 's|^storeMgmtdDirectory.*|storeMgmtdDirectory = '$BEEGFS_MGMT'|g' /etc/beegfs/beegfs-mgmtd.conf
sed -i 's/^sysMgmtdHost.*/sysMgmtdHost = '$MGMT_HOSTNAME'/g' /etc/beegfs/beegfs-admon.conf
#
systemctl daemon-reload
systemctl enable beegfs-mgmtd.service
systemctl enable beegfs-mgmtd.service
