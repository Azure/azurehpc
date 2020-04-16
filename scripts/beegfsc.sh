#!/bin/bash
#
MGMT_HOSTNAME=$1
SHARE_SCRATCH=/beegfs

yum install -y beegfs-client beegfs-helperd beegfs-utils

sed -i 's/^sysMgmtdHost.*/sysMgmtdHost = '$MGMT_HOSTNAME'/g' /etc/beegfs/beegfs-client.conf
if [ -d "/usr/src/ofa_kernel/default/include" ]; then
sed -i 's#^buildArgs=.*#buildArgs=-j8 OFED_INCLUDE_PATH=/usr/src/ofa_kernel/default/include#g' /etc/beegfs/beegfs-client-autobuild.conf
fi
echo "$SHARE_SCRATCH /etc/beegfs/beegfs-client.conf" > /etc/beegfs/beegfs-mounts.conf

systemctl daemon-reload
systemctl enable beegfs-helperd.service
systemctl enable beegfs-client.service
systemctl start beegfs-helperd.service
systemctl start beegfs-client.service
