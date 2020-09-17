#!/bin/bash
#
BEEGFS_MGMT_HOST=$1
#
yum install -y xauth
yum install -y beegfs-admon
yum install -y java

sed -i 's/^sysMgmtdHost.*/sysMgmtdHost = '$BEEGFS_MGMT_HOST'/g' /etc/beegfs/beegfs-admon.conf
#
systemctl start beegfs-admon.service
