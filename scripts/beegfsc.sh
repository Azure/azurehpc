#!/bin/bash
#
MGMT_HOSTNAME=$1

yum install -y beegfs-client beegfs-helperd beegfs-utils

sed -i 's/^sysMgmtdHost.*/sysMgmtdHost = '$MGMT_HOSTNAME'/g' /etc/beegfs/beegfs-client.conf
sed -i 's/^sysMgmtdHost.*/sysMgmtdHost = '$MGMT_HOSTNAME'/g' /etc/beegfs/beegfs-client.conf

systemctl daemon-reload
systemctl enable beegfs-helperd.service
systemctl enable beegfs-client.service
