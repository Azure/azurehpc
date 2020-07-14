#!/bin/bash
#
BEEGFS_MGMT_HOST=$1
#
yum install -y xauth
yum install -y beegfs-admon

sed -i 's/^sysMgmtdHost.*/sysMgmtdHost = '$MGMT_MGMT_HOST'/g' /etc/beegfs/beegfs-admon.conf
#
systemctl start beegfs-admon.service
