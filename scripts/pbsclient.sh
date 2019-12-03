#!/bin/bash

# arg: $1 = pbs_server
pbs_server=$1

if [ "$(rpm -qa pbspro-execution)" = "" ];then
    sudo yum install -y pbspro-execution-19.1.1-0.x86_64.rpm

    sudo sed -i "s/CHANGE_THIS_TO_PBS_PRO_SERVER_HOSTNAME/${pbs_server}/g" /etc/pbs.conf
    sudo sed -i "s/CHANGE_THIS_TO_PBS_PRO_SERVER_HOSTNAME/${pbs_server}/g" /var/spool/pbs/mom_priv/config
    sudo sed -i "s/^if /#if /g" /opt/pbs/lib/init.d/limits.pbs_mom
    sudo sed -i "s/^fi/#fi /g" /opt/pbs/lib/init.d/limits.pbs_mom
    sudo systemctl enable pbs
    sudo systemctl start pbs

    /opt/pbs/bin/qmgr -c "c n $(hostname)"
else
    echo "PBS client was already installed"
fi
