#!/bin/bash
#
MGMT_HOSTNAME=$1
SHARE_SCRATCH=/beegfs

yum install -y beegfs-client beegfs-helperd beegfs-utils

sed -i 's/^sysMgmtdHost.*/sysMgmtdHost = '$MGMT_HOSTNAME'/g' /etc/beegfs/beegfs-client.conf
echo "$SHARE_SCRATCH /etc/beegfs/beegfs-client.conf" > /etc/beegfs/beegfs-mounts.conf

systemctl daemon-reload
systemctl enable beegfs-helperd.service
systemctl enable beegfs-client.service
systemctl start beegfs-helperd.service
systemctl start beegfs-client.service
