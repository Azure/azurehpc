#!/bin/bash
#
BEEGFS_MGMT=$1
#
yum install -y beegfs-mgmtd beegfs-helperd beegfs-utils
mkdir -p $BEEGFS_MGMT
sed -i 's|^storeMgmtdDirectory.*|storeMgmtdDirectory = '$BEEGFS_MGMT'|g' /etc/beegfs/beegfs-mgmtd.conf
#
systemctl daemon-reload
systemctl enable beegfs-mgmtd.service
systemctl start beegfs-mgmtd.service
